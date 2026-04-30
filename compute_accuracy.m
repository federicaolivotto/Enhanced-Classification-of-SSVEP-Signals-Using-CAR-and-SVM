function accuracy = compute_accuracy(labels, outputs)
    % Compute accuracy
    C = confusionmat(labels, outputs);
    accuracy = sum(diag(C)) / sum(C(:)) * 100;
end