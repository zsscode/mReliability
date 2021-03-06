function [KAPPA, P_O, P_C] = mKAPPA(CODES, CATEGORIES, SCALE)
% Calculate Cohen's/Conger's kappa coefficient using generalized formulas
%   [KAPPA, P_O, P_C] = mKAPPA(CODES, CATEGORIES, SCALE)
%
%   CODES should be a numerical matrix where each row corresponds to a
%   single item of measurement (e.g., participant or question) and each
%   column corresponds to a single source of measurement (i.e., rater).
%   This function can handle any number of raters and values.
%
%   CATEGORIES is an optional parameter specifying the possible categories
%   as a numerical vector. If this variable is not specified, then the
%   possible categories are inferred from the CODES matrix. This can
%   underestimate reliability if all possible categories aren't used.
%
%   SCALE is an optional parameter specifying the scale of measurement:
%   -Use 'nominal' for unordered categories (default)
%   -Use 'ordinal' for ordered categories of unequal size
%   -Use 'interval' for ordered categories with equal spacing
%   -Use 'ratio' for ordered categories with equal spacing and a zero point
%
%   KAPPA is a chance-adjusted index of agreement.
%
%   P_O is the percent observed agreement (from 0.000 to 1.000).
%
%   P_C is the estimated percent chance agreement (from 0.000 to 1.000).
%
%   Example usage: [KAPPA,P_O,P_C] = mKAPPA(smiledata,[0,1],'nominal');
%
%   (c) Jeffrey M Girard, 2016
%   
%   References:
%   
%   Cohen, J. (1960). A coefficient of agreement for nominal scales.
%   Educational and Psychological Measurement, 20(1), 37�46.
%
%   Cohen, J. (1968). Weighted kappa: Nominal scale agreement with
%   provision for scaled disagreement or partial credit. Psychological
%   Bulletin, 70(4), 213�220.
%
%   Conger, A. J. (1980). Integration and generalization of kappas for
%   multiple raters. Psychological Bulletin, 88(2), 322�328.
%   
%   Gwet, K. L. (2014). Handbook of inter-rater reliability: The definitive
%   guide to measuring the extent of agreement among raters (4th ed.).
%   Gaithersburg, MD: Advanced Analytics.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Remove items with all missing codes
CODES(all(~isfinite(CODES),2),:) = [];
%% Calculate basic descriptives
[n,r] = size(CODES);
x = unique(CODES);
x(~isfinite(x)) = [];
if nargin < 2
    CATEGORIES = x;
    SCALE = 'nominal';
elseif nargin < 3
    SCALE = 'nominal';
end
if isempty(CATEGORIES)
    CATEGORIES = x;
end
CATEGORIES = unique(CATEGORIES(:));
q = length(CATEGORIES);
%% Output basic descriptives
fprintf('Number of items = %d\n',n);
fprintf('Number of raters = %d\n',r);
fprintf('Possible categories = %s\n',mat2str(CATEGORIES));
fprintf('Observed categories = %s\n',mat2str(x));
fprintf('Scale of measurement = %s\n',SCALE);
%% Check for valid data from multiple raters
if n < 1
    KAPPA = NaN;
    fprintf('\nERROR: At least 1 item is required.\n')
    return;
end
if r < 2
    KAPPA = NaN;
    fprintf('\nERROR: At least 2 raters are required.\n');
    return;
end
if any(ismember(x,CATEGORIES)==0)
    KAPPA = NaN;
    fprintf('ERROR: Categories were observed in CODES that were not included in CATEGORIES.\n');
    return;
end
%% Calculate weights based on data scale
w = nan(q);
for k = 1:q
    for l = 1:q
        switch SCALE
            case 'nominal'
                w = eye(q);
            case 'ordinal'
                if k==l
                    w(k,l) = 1;
                else
                    M_kl = nchoosek((max(k,l) - min(k,l) + 1),2);
                    M_1q = nchoosek((max(1,q) - min(1,q) + 1),2);
                    w(k,l) = 1 - (M_kl / M_1q);
                end
            case 'interval'
                if k==l
                    w(k,l) = 1;
                else
                    dist = abs(CATEGORIES(k) - CATEGORIES(l));
                    maxdist = max(CATEGORIES) - min(CATEGORIES);
                    w(k,l) = 1 - (dist / maxdist);
                end
            case 'ratio'
                w(k,l) = 1 - (((CATEGORIES(k) - CATEGORIES(l)) / (CATEGORIES(k) + CATEGORIES(l)))^2) / (((max(CATEGORIES) - min(CATEGORIES)) / (max(CATEGORIES) + min(CATEGORIES)))^2);
                if CATEGORIES(k)==0 && CATEGORIES(l)==0, w(k,l) = 1; end
            otherwise
                error('Scale must be nominal, ordinal, interval, or ratio');
        end
    end
end
%% Create n-by-q matrix (rater counts in item by category matrix)
nxq = zeros(n,q);
for k = 1:q
    codes_k = CODES == CATEGORIES(k);
    nxq(:,k) = codes_k * ones(r,1);
end
nxq_w = transpose(w * transpose(nxq));
%% Create r-by-q matrix (item counts in rater by category matrix)
rxq = zeros(r,q);
for k = 1:q
    temp = transpose(CODES) == CATEGORIES(k);
    rxq(:,k) = temp * ones(n,1);
end
%% Calculate percent observed agreement
r_i = nxq * ones(q,1);
observed = (nxq .* (nxq_w - 1)) * ones(q,1);
nprime = sum(r_i >= 2);
possible = r_i .* (r_i - 1);
P_O = sum(observed(r_i >= 2) ./ (possible(r_i >= 2))) ./ nprime;
%% Calculate percent chance agreement
n_g = rxq * ones(q,1);
p_gk = rxq ./ (n_g * ones(1,q));
pbar_k = (transpose(p_gk) * ones(r,1)) ./ r;
ssq_kl = (transpose(p_gk) * p_gk - r .* pbar_k * transpose(pbar_k)) ./ (r - 1);
P_C = sum(sum(w .* (pbar_k * transpose(pbar_k) - ssq_kl ./ r)));
%% Calculate reliability point estimate
KAPPA = (P_O - P_C) / (1 - P_C);
%% Output reliability and variance components
fprintf('Percent observed agreement = %.3f\n',P_O);
fprintf('Percent chance agreement = %.3f\n',P_C);
if r==2
    fprintf('\nCohen''s kappa coefficient = %.3f\n',KAPPA);
else
    fprintf('\nConger''s kappa coefficient = %.3f\n',KAPPA);
end

end