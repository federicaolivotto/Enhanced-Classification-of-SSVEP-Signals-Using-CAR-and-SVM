function Xref = generate_reference_signals(fstim, Nh, t)
    % Generate reference signals for each stimulus frequency
    Xref = [];
    for i = 1:numel(fstim)
        Y = [];
        for n = 1:Nh
            tp(1,:) = sin(2*pi*(n*fstim(i))*t);
            tp(2,:) = cos(2*pi*(n*fstim(i))*t);
            Y = [Y; tp];
        end
        Xref(:,:,i) = Y';
    end
end