local _, core = ...

function core:IsSafeNumber(val)
    return val ~= nil and not issecretvalue(val);
end

function core:IsSafePositiveNumber(val)
    return val ~= nil and not issecretvalue(val) and val > 0;
end
