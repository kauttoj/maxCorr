function d = getPart(obj,i)
% d = obj.getPart(i)
%
% Returns the data for part i of a multi-part data set.
%

if (length(obj.sdata)),
   d = obj.sdata;
else
   d = obj.loadFunc(obj.userData,i,obj.N,obj.verb);
end

%% added by JK
bad_items = find(any(isnan(d)));
if ~isempty(bad_items),
    d(:,bad_items)=[];
    warning('Set %i: Removing %i bad timeseries, with %i remaining',i,length(bad_items),size(d,2));
end

if length(obj.data_size)==0
   obj.data_size = size(d);
   if (isa(d,'msMatrix'))
      obj.data_type=d.type();
   else
      obj.data_type=class(d);
   end
end

T=[];
if (length(obj.CR)), T = obj.CR; end;
if (length(obj.IR)), T = [T obj.IR(:,:,i)]; end;
if (length(T)),
   if (isa(d,'msMatrix')), d = d.toType(); end;
   d = d - pinv(T)'*(T'*d);
end
d = maxCorr.normalize(d);

end


