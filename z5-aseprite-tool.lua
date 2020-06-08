json = dofile("json.lual")

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
    dialog:close{}
end

function editBlock(blockID, bt)
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
            bt[blockID]["sprite"]["frames"][i] = nil
        end
        }

        numberOfFrames = numberOfFrames+1
    end
    dlg:separator{}
    dlg:button{id="addframe",text="add frame", 
    onclick= function ()
        addFrame(bt[blockID])
        saveBlock(dlg,bt[blockID])
    end}
    dlg:newrow{}
    dlg:button{ id="save", text="save",
        onclick= function()
            saveBlock(dlg,bt[blockID])
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

function openbt(btj,minNum)
    local fileContents = readAll(btj)
    local backupFile = io.open(btj .. ".bak","w")
    backupFile:write(json.decode(json.encode(fileContents)))
    backupFile:close()
    local blockTable = json.decode(fileContents)
    local dlg = Dialog()
    local counter = 0
    local length = 0
    for bid,block in pairs(blockTable) do
        length = length + 1
        if block["ID"] >= minNum and counter < 15 then
            dlg:button{id = block["ID"], label =block["ID"], text = block["name"], 
            onclick= function ()
                editBlock(bid,blockTable) 
            end
            }
            dlg:newrow()
            counter = counter + 1
        end
    end
    dlg:separator{}
    dlg:button{id = "newBlock", text = "+"}
    dlg:newrow()
    dlg:button{ id="save", text="save",
        onclick= function()
            save(blockTable,btj)
            dlg:close()
        end
    }
    dlg:button{ id="cancel", text="Cancel" , onclick=function () dlg:close{} end}
    dlg:show{wait = false}
end

local dlg = Dialog()
dlg:file{ id="btjson",
    label="Open blocktable.json",
    title="Open blockTable.json",
    open=true,
    save=false,
    filename="/home/klanc/Projects/Uni/TFG/Z5/data/blockTable.json",
    filetypes={ "json" },
}
dlg:number{id="num", label="minNum"}
dlg:button{ id="ok", text="OK"  }
dlg:button{ id="cancel", text="Cancel"  }
dlg:show{}
local data = dlg.data
if data.ok then
    openbt(data.btjson,data.num)
end
if data.cancel then
    return
end
