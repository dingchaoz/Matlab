function a = nonan(a)
%Returns a vactor with the NaN values stripped out
    a = a(~isnan(a));
end
