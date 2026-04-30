function [Wx,Wy,r] = myCCA(X,Y)
    % Ensure that X and Y have the same number of columns (time points)
    if size(X, 2) ~= size(Y, 2)
        error('The number of columns (time points) in X and Y must match.');
    end

    % Canonical Correlation Analysis
    z = [X;Y];
    C = cov(z.');
    sx = size(X,1);
    sy = size(Y,1);
    Cxx = C(1:sx, 1:sx) + 10^(-8)*eye(sx);
    Cxy = C(1:sx, sx+1:sx+sy);
    Cyx = Cxy';
    Cyy = C(sx+1:sx+sy, sx+1:sx+sy) + 10^(-8)*eye(sy);
    invCyy = inv(Cyy);
    C = inv(Cxx)*Cxy*invCyy*Cyx;

    % Eigenvalue decomposition
    [Wx,r]= eig(C);
    r = sqrt(real(r));      % Canonical correlations

    % Sort correlations
    V = fliplr(Wx);         % Reverse order of eigenvectors
    r = flipud(diag(r));    % Extract eigenvalues and reverse their order
    [r,I]= sort((real(r))); % Sort reversed eigenvalues in ascending order
    r = flipud(r);          % Restore sorted eigenvalues into descending order
    for j = 1:length(I)
        Wx(:,j) = V(:,I(j));  % Sort reversed eigenvectors in ascending order
    end
    Wx = fliplr(Wx);        % Restore sorted eigenvectors into descending order

    % Calculate Wy
    Wy = inv(Cyy)*Cyx*Wx;   % Basis in Y
    Wx = Wx(:,1:end);
end