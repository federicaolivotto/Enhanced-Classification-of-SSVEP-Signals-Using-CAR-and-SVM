function X = apply_car_filter(X)
    % Apply Common Average Reference (CAR) filter
    ref = mean(X, 2);
    X = X - ref;
end