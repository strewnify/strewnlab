function m = logb(x, b)
%LOGB Custom logarithm function with a specified base.
%   M = LOGB(X, B) calculates the logarithm of X with respect to base B.
%   This function is useful when you need to compute logarithms for bases
%   other than the natural logarithm (e) or base 10, which are directly
%   supported by MATLAB's built-in functions `log` and `log10`.
%
%   Input Arguments:
%   ----------------
%   X : The number for which to calculate the logarithm. X must be a
%       positive scalar or array.
%   B : The base of the logarithm. B must be a positive scalar and not equal to 1.
%
%   Output Arguments:
%   -----------------
%   M : The logarithm of X with base B.
%
%   Mathematical Principle:
%   -----------------------
%   The function uses the change-of-base formula for logarithms:
%   log_b(x) = log_k(x) / log_k(b)
%   where k can be any convenient base. In this implementation, base 2 is
%   used for the calculation due to MATLAB's efficient `log2` function.
%
%   Example:
%   --------
%   % Calculate log base 2 of 8:
%   logb(8, 2) % Expected output: 3
%
%   % Calculate log base 10 of 100:
%   logb(100, 10) % Expected output: 2
%
%   See Also:
%   ---------
%   log     - Natural logarithm.
%   log10   - Common (base 10) logarithm.
%   log2    - Base 2 logarithm and dissect floating point numbers.

% Input validation
if nargin ~= 2
    error('logb:IncorrectNumberOfInputs', 'Requires two input arguments.');
end

if any(x <= 0, 'all')
    error('logb:InvalidInputX', 'Log argument must be positive.');
end

if any(b <= 0, 'all') || any(b == 1, 'all')
    error('logb:InvalidInputB', 'Log base must be positive and not equal to 1.');
end

% Calculate the logarithm using the change-of-base formula
m = log2(x) / log2(b);

end