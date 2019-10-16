aliveai_trader={}
minetest.register_on_player_receive_fields(function(player, form, pressed)
	
	if form=="aliveai_worker.form" then

		if not pressed.quit then return end

		local pname=player:get_player_name()
		local self=aliveai_trader.user[pname]

		if not pressed.order or not (self and self.object) then
			if self and self.offering then self.offering=nil end
			aliveai_trader.user[pname]=nil
			aliveai.give_to_bot(self,player)
			return self
		end

		local names={}
		local name=""
		local name2=""
		local node=""
		local pos1={}
		local pos2={}

		if pressed.work1=="dig" then
			local n=pressed.work2.split(pressed.work2,",")
			for i, v in pairs(n) do
				if v~=n and v~="" and (minetest.registered_nodes[v] or string.find(v,"group:")~=nil) then
					table.insert(names,v)
				else
					minetest.chat_send_player(pname, v .." is not a node or group")
					return
				end 
			end
		elseif pressed.work1=="take from inventory" then
			local n=pressed.work2.split(pressed.work2,",")
			local x=tonumber(n[1])
			local y=tonumber(n[2])
			local z=tonumber(n[3])
			name=n[4]
			if name==nil or name=="" then name="main" end
			if x and y and z then
				pos1={x=x,y=y,z=z}
			else
				if not (x and y and z) then minetest.chat_send_player(pname, "not all dimensions (x,y,z) is added")
				else
					minetest.chat_send_player(pname, "void position or name")
				end
				return
			end
		end

		if pressed.work3=="place" then
			local n=pressed.work4.split(pressed.work4,",")
			local x=tonumber(n[1])
			local y=tonumber(n[2])
			local z=tonumber(n[3])
			node=n[4]
			if x and y and z and node and minetest.registered_nodes[node] then
				pos2={x=x,y=y,z=z}
			else
				if not (x and y and z) then minetest.chat_send_player(pname, "not all dimensions (x,y,z) is added")
				elseif node and not minetest.registered_nodes[node] then minetest.chat_send_player(pname, node .. " is not a node")
				else
					minetest.chat_send_player(pname, "void position or node")
				end
				return
			end
		elseif pressed.work3=="add to inventory" then
			local n=pressed.work4.split(pressed.work4,",")
			local x=tonumber(n[1])
			local y=tonumber(n[2])
			local z=tonumber(n[3])
			name2=n[4]
			if name2==nil or name2=="" then name2="main" end
			if x and y and z then
				pos2={x=x,y=y,z=z}
			else
				minetest.chat_send_player(pname, "not all dimensions (x,y,z) is added")
				return
			end
		end

		self.work_dig=nil
		self.work_take=nil
		self.work_take_name=nil
		self.work_place=nil
		self.work_place_name=nil
		self.work_add=nil
		self.work_add_name=nil
		self.work_name=pname
		self.work_step=1

		if pressed.work1=="dig" then
			self.work_dig=names
		elseif pressed.work1=="take from inventory" then
			self.work_take=pos1
			self.work_take_name=name
		end

		if pressed.work3=="place" then
			self.work_place=pos2
			self.work_place_name=node
		elseif pressed.work3=="add to inventory" then
			self.work_add=pos2
			self.work_add_name=name2
		end

		if pressed.quit or not (self and self.object) then
			if self and self.offering then self.offering=nil end
			aliveai_trader.user[pname]=nil
			return self
		end
		aliveai_trader.user[pname]=nil
		return self
	end
end)


aliveai_trader.form2=function(self,player)
	local name=player:get_player_name()
	if not aliveai_trader.user then aliveai_trader.user={} end
	aliveai_trader.user[name]=self
	local work1=""
	local work2=""
	local id1=1
	local id2=1
	if self.work_dig then
		local c=""
		for i, v in pairs(self.work_dig) do
			if i>1 then c="," end
			work1=work1 .. c .. v
		end
		id1=1
	end
	if self.work_take then
		work1=self.work_take.x .. "," .. self.work_take.y .."," .. self.work_take.z .."," ..self.work_take_name
		id1=2
	end
	if  self.work_place then
		work2=self.work_place.x .. "," .. self.work_place.y .."," .. self.work_place.z .."," ..self.work_place_name
		id2=1
	end
	if  self.work_add then
		work2=self.work_add.x .. "," .. self.work_add.y .."," .. self.work_add.z .."," ..self.work_add_name
		id2=2
	end

	if not (self.work_place or self.work_add) then
		local pppos=player:get_pos()
		pppos=aliveai.roundpos(pppos)
		work2=aliveai.strpos(pppos)
	end

	local gui=""
	.."size[10,4]"
	.."tooltip[work2;dig: default:dirt,group:stone...\ntake: x,y,z,inventory_name (default inventory name is main)]"
	.."tooltip[work4;place: default:dirt,group:stone...\nadd: x,y,z,inventory_name (default inventory name is main)]"
	.."dropdown[0,0;10,1;work1;dig,take from inventory;" .. id1 .."]"
	.. "field[0,1;10,1;work2;;" .. work1 .."]"
	.."dropdown[0,2;10,4;work3;place,add to inventory;" .. id2 .."]"
	.. "field[0,3;10,1;work4;;" .. work2 .."]"
	.."button_exit[0,3.2;2,2;order;order]"
	minetest.after((0.1), function(gui)
		return minetest.show_formspec(player:get_player_name(), "aliveai_worker.form",gui)
	end, gui)
end

aliveai.create_bot({
		description="Does players bidding",
		name="slave",
		texture="aliveai_worker.png",
		building=0,
		annoyed_by_staring=0,
		hp=40,
		name_color="ffff00",
		crafting=0,
	spawn=function(self)
		self.botname="worker: " .. self.botname
		self.object:set_properties({nametag=self.botname,nametag_color="#" .. self.botname})
	end,
	click=function(self,clicker)
		if self.work_name and self.work_name~=clicker:get_player_name() then return end
		self.offering=true
		aliveai.lookat(self,clicker:get_pos())
		aliveai_trader.form2(self,clicker)
	end,
	on_step=function(self,dtime)
		if self.offering then
			aliveai.rndwalk(self,false)
			aliveai.stand(self)
			return self
		end
--path
		if self.work_path and self.path then
			aliveai.path(self)
			if self.done=="path" or (math.random(1,10)==1 and aliveai.distance(self,self.work_path)<self.arm and aliveai.visiable(self,self.work_path)) then
				self.done=""
				aliveai.lookat(self,self.work_path)
				self.work_path=nil
	--take from inventory
				if self.work_step==1 and self.work_take then
					local meta=minetest.get_meta(self.work_take)
					local inv = meta:get_inventory()
					local owner=meta:get_string("owner")
					if owner=="" or owner==self.work_name then
						for i=1,inv:get_size(self.work_take_name),1 do
							local it=inv:get_stack(self.work_take_name,i):get_name()
							local co=inv:get_stack(self.work_take_name,i):get_count()
							inv:set_stack(self.work_take_name,i,nil)
							aliveai.invadd(self,it,co)
						end
					end
					self.work_step=2
					return self
				end
	--place
				if self.work_step==2 and self.work_place then
					aliveai.place(self,self.work_place,self.work_place_name)
					self.work_step=1
					return self
				end
	--add to inventory
				if self.work_step==2 and self.work_add then
					local meta=minetest.get_meta(self.work_add)
					local inv = meta:get_inventory()
					local owner=meta:get_string("owner")
					if owner=="" or owner==self.work_name then
						for it, co in pairs(self.inv) do
							if inv:room_for_item(self.work_add_name,it .. " " .. co) then
								inv:add_item(self.work_add_name,it .. " " .. co)
								aliveai.invadd(self,it,-co)
							end
						end
					end
					self.work_step=1
					return self
				end
			end
			return self
		end
--dig
		if self.work_step==1 and self.work_dig then
			if not self.mine then
				aliveai.add_mine(self,self.work_dig,10)
				self.crafting=0
				return
			elseif math.random(1,20)==1 then
				for it, co in pairs(self.inv) do
					if co>9 then
						aliveai.exit_mine(self)
						self.work_step=2
						break
					end
				end
			end
		end
--take from inventory
		if self.work_step==1 and self.work_take then
			local p=aliveai.neartarget(self,self.work_take,self.arm,0)
			if p then
				local pos=aliveai.roundpos(self.object:get_pos())
				pos.y=pos.y-1
				p=aliveai.creatpath(self,pos,aliveai.roundpos(p))
				if p then
					self.path=p
					self.work_path=self.work_take
				end
			end
			return
		end
--place
		if self.work_step==2 and self.work_place then
			local p=aliveai.neartarget(self,self.work_place,self.arm,0)
			if p then
				local pos=aliveai.roundpos(self.object:get_pos())
				pos.y=pos.y-1
				p=aliveai.creatpath(self,pos,aliveai.roundpos(p))
				if p then
					self.path=p
					self.work_path=self.work_place
				end
			end
			return
		end
--add to inventory
		if self.work_step==2 and self.work_add then
			local p=aliveai.neartarget(self,self.work_add,self.arm,0)
			if p then
				local pos=aliveai.roundpos(self.object:get_pos())
				pos.y=pos.y-1
				p=aliveai.creatpath(self,pos,aliveai.roundpos(p))
				if p then
					self.path=p
					self.work_path=self.work_add
				end
			end
			return
		end
	end,
})
