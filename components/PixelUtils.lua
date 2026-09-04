local _, core = ...

function core:GetPixelUnit()
    local _, screenHeight = GetPhysicalScreenSize();
    return UIParent:GetHeight() / screenHeight;
end

-- UI units are not physical pixels (UIParent is scaled), so every size and offset that has to land
-- on an exact pixel is rounded to a whole number of pixels; otherwise a 1px border ends up straddling
-- two pixel rows and renders as 2px on one side and nothing on the other
local function snap(units)
    if not units or units == 0 then return 0 end;
    local pixels = math.floor(math.abs(units) / core.pixel + 0.5);
    return (units < 0 and -1 or 1) * pixels * core.pixel;
end

function core:SetPixelPoint(region, point, relativeTo, relativePoint, x, y)
    region:SetPoint(point, relativeTo, relativePoint, snap(x), snap(y));
end

function core:SetPixelSize(region, width, height)
    region:SetSize(snap(width), snap(height));
end

function core:EvenPixels(units)
    local pixels = math.max(2, math.floor(units / core.pixel + 0.5));
    if pixels % 2 == 1 then
        pixels = pixels + 1;
    end
    return pixels * core.pixel;
end

function core:SnapToPixelGrid(frame)
    if not frame then return end;

    local left, bottom = frame:GetLeft(), frame:GetBottom();
    if not left or not bottom then return end;

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1);
    if not point then return end;

    local dx, dy = left - snap(left), bottom - snap(bottom);
    if dx == 0 and dy == 0 then return end;

    frame:SetPoint(point, relativeTo, relativePoint, (x or 0) - dx, (y or 0) - dy);
end

function core:InsetBarInBackground(bar, bg)
    bar:ClearAllPoints();
    core:SetPixelPoint(bar, "TOPLEFT", bg, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(bar, "BOTTOMRIGHT", bg, "BOTTOMRIGHT", -core.pixel, core.pixel);
end
