function [ test_n ] = testrand( mean, stdev, sigma_thresh, minvalue, maxvalue )
for r_idx = 1:1000000
    test_n(r_idx) = randnsigma( mean, stdev, sigma_thresh, minvalue, maxvalue );
end
hist(test_n)