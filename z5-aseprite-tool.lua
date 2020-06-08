json = dofile("json.lual")

pageSize = 15

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function getCollider(c)
    collider = "box"
    if c == 1 then
        collider = "ramp"
    end
    if c == 2 then
        collider = "half"
    end
    return collider
end

function addFrame(block)
    local sprite = app.activeSprite
    block["sprite"]["frames"][#block["sprite"]["frames"]+1]= {}
    block["sprite"]["frames"][#block["sprite"]["frames"]]["startX"] = sprite.selection.bounds.x
    block["sprite"]["frames"][#block["sprite"]["frames"]]["startY"] = sprite.selection.bounds.y
    block["sprite"]["frames"][#block["sprite"]["frames"]]["sizeX"] = 16
    block["sprite"]["frames"][#block["sprite"]["frames"]]["sizeY"] = 16
end

function saveBlock(dialog,block)
    block["name"]= dialog.data.name
    block["visible"]= dialog.data.visible
    block["solid"]= dialog.data.solid
    block["opaque"]=dialog.data.opaque
    block["mass"]=dialog.data.mass
    if dialog.data.solid then
        block["collider"] = 0
        if dialog.data.collider == "ramp" then
            block["collider"] = 1
        end
        if dialog.data.collider == "half" then
            block["collider"] = 2
        end
    end
end

function newBlock(bt)
    table.insert(bt,{})
    bt[#bt]["ID"] = #bt - 1
    bt[#bt]["name"] = "newBlock"
    bt[#bt]["visible"] = true
    bt[#bt]["solid"] = true
    bt[#bt]["opaque"] = true
    bt[#bt]["mass"] = 1000
    bt[#bt]["collider"] = 0
    bt[#bt]["sprite"] = {}
    bt[#bt]["sprite"]["path"] = "spritesheet.png"
    bt[#bt]["sprite"]["frames"] = {}
end

function editBlock(blockID, bt,parentdlg,minNum,btjname)
    local dlg = Dialog()
    dlg:label{label="ID: " .. bt[blockID]["ID"]}
    dlg:newrow{}
    dlg:entry{id="name",label="name",text=bt[blockID]["name"]}
    dlg:newrow{}
    dlg:check{id="visible",label="visible",selected=bt[blockID]["visible"]}
    dlg:newrow{}
    dlg:check{id="solid",label="solid",selected=bt[blockID]["solid"]}
    dlg:newrow{}
    dlg:check{id="opaque",label="opaque",selected=bt[blockID]["opaque"]}
    dlg:newrow{}
    dlg:number{id="mass",label="mass",text = tostring(bt[blockID]["mass"])}
    dlg:newrow{}
    dlg:combobox{id="collider",label="collider", option = getCollider(bt[blockID]["collider"]), options={"box","ramp","half"}}
    numberOfFrames = 0
    for i,frame in pairs(bt[blockID]["sprite"]["frames"]) do
        dlg:label{id="fl"..i ,label="frame ".. i,text=frame["startX"]..", "..frame["startY"]}
        dlg:button{id="fd"..i,text="-",
        onclick=function()
            saveBlock(dlg,bt[blockID])
            bt[blockID]["sprite"]["frames"][i] = nil
            dlg:close{}
            editBlock(blockID,bt)
        end
        }

        numberOfFrames = numberOfFrames+1
    end
    dlg:separator{}
    dlg:button{id="addframe",text="add frame", 
    onclick= function ()
        addFrame(bt[blockID])
        saveBlock(dlg,bt[blockID])
        dlg:close{}
        editBlock(blockID,bt)
    end}
    dlg:newrow{}
    dlg:button{ id="save", text="Save",
        onclick= function()
            saveBlock(dlg,bt[blockID])
            dlg:close{}
            parentdlg:close{}
            openbt(bt,btjname,minNum)
        end
        }
    dlg:button{ id="cancel", text="Cancel" , onclick=function () dlg:close{} end }
    dlg:show{wait = false}
end

function save(bt,btPath)
    local outputFile = io.open(btPath, "w")
    outputFile:write(json.encode(bt))
    outputFile:close()
end

function openbt(bt,btjname,minNum)
    local dlg = Dialog()
    local counter = 0
    local length = 0
    for bid,block in pairs(bt) do
        length = length + 1
        if bid >= minNum and counter < 15 then
            dlg:button{id = bid-1, label = bid-1, text = block["name"], 
            onclick= function ()
                editBlock(bid,bt,dlg,minNum,btjname) 
            end
            }
            dlg:newrow()
            counter = counter + 1
        end
    end
    dlg:separator{}
    dlg:button{id = "newBlock", text = "+",
    onclick = function()
        newBlock(bt)
        editBlock(#bt,bt,dlg,minNum,btjname)
    end
    }   
    dlg:newrow()
    dlg:button{id="prev",text="<",onclick=
    function()
        local newStart = minNum - pageSize
        if newStart < 0 then
            newStart = 0
        end
        dlg:close{}
        openbt(bt,btjname,newStart)
    end
    }
    dlg:button{id="next",text=">",onclick=
    function()
        local newStart = minNum + pageSize
        if newStart < 0 then
            newStart = 0
        end
        dlg:close{}
        openbt(bt,btjname,newStart)
    end
    }
    dlg:newrow()
    dlg:button{ id="save", text="Save",
        onclick= function()
            save(bt,btjname)
            dlg:close()
        end
    }
    dlg:button{ id="cancel", text="Cancel" , onclick=function () dlg:close{} end}
    dlg:show{wait = false}
end


--MAIN
local dlg = Dialog()
dlg:file{ id="btjson",
    label="Open blocktable.json",
    title="Open blockTable.json",
    open=true,
    save=false,
    filename="/home/klanc/Projects/Uni/TFG/Z5/data/blockTable.json",
    filetypes={ "json" },
}
dlg:button{ id="ok", text="OK"  }
dlg:button{ id="cancel", text="Cancel"  }
dlg:show{}
local data = dlg.data
if data.ok then
    local fileContents = readAll(data.btjson)
    local blockTable = json.decode(fileContents)
    openbt(blockTable,data.btjson,0)
end
if data.cancel then
    return
end

--[[
  TODO

  Ability to delete blocks

]]
