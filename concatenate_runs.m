function EEGdata = concatenate_runs(data)
    % Concatenate data across runs (merges together the trials from all the
    % 6 blocks)
    EEGdata = cat(3, data(:,:,:,1), data(:,:,:,2), data(:,:,:,3), data(:,:,:,4), data(:,:,:,5), data(:,:,:,6));
end