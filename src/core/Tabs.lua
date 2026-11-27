local Components,Theme=PerHour.Components,PerHour.Theme

function Components:CreateTabBox(parent)
    local box=CreateFrame("Frame",nil,parent)
    -- Keep the entire box behind sibling scroll frames, including pooled rows.
    box:SetFrameLevel(parent:GetFrameLevel())
    local corner=box:CreateTexture(nil,"OVERLAY",nil,2)
    corner:SetAtlas("Options_InnerFrame",true)
    local width,height=corner:GetWidth(),corner:GetHeight()
    local left,top,_,_,right,_,_,bottom=corner:GetTexCoord()
    local edge=8
    box.Background=box:CreateTexture(nil,"BACKGROUND")
    box.Background:SetPoint("TOPLEFT",box,"TOPLEFT",edge,-edge)
    box.Background:SetPoint("BOTTOMRIGHT",box,"BOTTOMRIGHT",-edge,edge)
    box.Background:SetColorTexture(unpack(Theme.tabContentBackground))
    local x={0,edge,width-edge,width}
    local y={0,edge,height-edge,height}
    box.BorderParts={}
    -- Keep the native border thickness and shade its interior separately.
    for row=1,3 do
        for column=1,3 do
            if row ~= 2 or column ~= 2 then
                local texture=#box.BorderParts == 0 and corner or box:CreateTexture(nil,"OVERLAY",nil,2)
                texture:SetAtlas("Options_InnerFrame")
                texture:SetTexCoord(left+(right-left)*x[column]/width,left+(right-left)*x[column+1]/width,
                    top+(bottom-top)*y[row]/height,top+(bottom-top)*y[row+1]/height)
                local vertical=row == 1 and "TOP" or "BOTTOM"
                local horizontal=column == 1 and "LEFT" or "RIGHT"
                if column == 2 then
                    texture:SetHeight(edge)
                    texture:SetPoint(vertical.."LEFT",box,vertical.."LEFT",edge,0)
                    texture:SetPoint(vertical.."RIGHT",box,vertical.."RIGHT",-edge,0)
                elseif row == 2 then
                    texture:SetWidth(edge)
                    texture:SetPoint("TOP"..horizontal,box,"TOP"..horizontal,0,-edge)
                    texture:SetPoint("BOTTOM"..horizontal,box,"BOTTOM"..horizontal,0,edge)
                else
                    texture:SetSize(edge,edge)
                    texture:SetPoint(vertical..horizontal,box,vertical..horizontal,0,0)
                end
                box.BorderParts[#box.BorderParts+1]=texture
            end
        end
    end
    return box
end

-- Options uses MinimalTabTemplate and a native radio group in Forever.
function Components:CreateTabs(parent,keys,onChanged)
    local tabs=CreateFrame("Frame",nil,parent)
    tabs:SetHeight(37)
    tabs.Buttons,tabs.Order,tabs.SelectedKey,tabs.Updating={},keys,false,false
    tabs.Group=CreateRadioButtonGroup()
    for _,key in ipairs(keys) do
        local button=CreateFrame("Button",nil,tabs,"MinimalTabTemplate")
        button.Key=key
        button.Text:SetText(key)
        button:SetWidth(button.Text:GetStringWidth()+40)
        tabs.Buttons[key]=button
        tabs.Group:AddButton(button)
    end
    tabs.Group:RegisterCallback(ButtonGroupBaseMixin.Event.Selected,function(self,button)
        self.SelectedKey=button.Key
        if not self.Updating then
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            onChanged(button.Key)
        end
    end,tabs)
    function tabs:Select(key)
        self.Updating=true
        self.Group:Select(self.Buttons[key])
        self.Updating=false
    end
    function tabs:SetAvailable(key,available)
        self.Buttons[key]:SetShown(available)
        local previous
        for _,name in ipairs(self.Order) do
            local button=self.Buttons[name]
            if button:IsShown() then
                button:ClearAllPoints()
                if previous then button:SetPoint("TOPLEFT",previous,"TOPRIGHT",5,0)
                else button:SetPoint("TOPLEFT",self,"TOPLEFT",8,0) end
                previous=button
            end
        end
    end
    tabs:SetAvailable(keys[1],true)
    return tabs
end
