local Pathfinding = newClass()


function Pathfinding:__new__()
end


function Pathfinding:searchPath( navMap, startNavNode, targetNavNode )
	if startNavNode == targetNavNode then return nil end
	self.navmap = navMap
	self.start, self.target = startNavNode, targetNavNode

	self.frontier = {}
	addToFrontier(self, self.start, 0 )

	self.cameFrom = {}
	self.cameFrom[ self.start:tostring() ] = nil

	self.costSoFar = {}
	self.costSoFar[ self.start:tostring() ] = 0

	-- print( '->start :', self.start.x, self.start.y)
	-- print( '->target:', self.target.x, self.target.y)
	while ( #self.frontier > 0 ) do
		local current = (table.remove( self.frontier, 1 )).n
		-- print('\n\nnew current picked up', current.x, current.y)
		if current == self.target then 
      		-- print('icicici')
      		break
      	end

		for i, linkTo in ipairs( current._links ) do

			local neighbor = linkTo._target 
			print(getActionCost(self, linkTo))
			local newCost = self.costSoFar[ current:tostring() ] + getActionCost(self, linkTo);
-- 
			if ( not self.costSoFar[ neighbor:tostring() ] or newCost < self.costSoFar[ neighbor:tostring() ] ) then
				self.costSoFar[ neighbor:tostring() ] = newCost
				
				addToFrontier( self, neighbor, newCost )
				self.cameFrom[ neighbor:tostring() ] = {node=current, link=linkTo}
			end

		end

	end

	return constructPathBackward( self )
end


function Pathfinding.drawPath( path )

	for i, link in ipairs( path ) do

		local fromTile = engine.map:getTileByIndex( link._from.x, link._from.y )
		local toTile = engine.map:getTileByIndex( link._target.x, link._target.y )
		
		-- draw nodes
		
		love.graphics.setColor( 0.2, 0.8, 0.4, 1 );
		if ( i == 1 ) then
			love.graphics.circle( "fill", fromTile.middle.x, fromTile.middle.y, TIL / 6 )
		end
		love.graphics.circle( "fill", toTile.middle.x, toTile.middle.y, TIL / 6 )

		-- draw links
		
		love.graphics.setColor( link._type == link.Action.Jump and {0.9, 0.8, 0.6, 1} or {0.2, 0.8, 0.4, 1} );
		love.graphics.line( fromTile.middle.x, fromTile.middle.y, toTile.middle.x, toTile.middle.y )

	end
end

function getActionCost(self, link)

	if ( link.action == NodeLink.Action.Jump ) then
		return 1
	end

	if ( link.action == NodeLink.Action.Fall ) then
		return 1
	end


	return 1
end

function addToFrontier(self, node, priority )
	local i = 1
	for k, v in pairs(self.frontier) do
		i = i + 1
		-- print('for', k, v, priority)
		if (priority < v.priority) then
			-- print('add to frontier', i, '\n')
			table.insert( self.frontier, i, {n=node, priority=priority } )
			return 
		end
	end

	-- if (#self.frontier == 0 or ) then
	-- print('add to frontier=0')

	table.insert( self.frontier, {n=node, priority=priority } )
	-- end



end


function constructPathBackward(self)

	local current = self.cameFrom[ self.target:tostring() ]
	local path = {}

	while ( current.node ~= self.start ) do

		table.insert( path, 1, current.link )
		current = self.cameFrom[ current.node:tostring() ]
	end

	-- if (current) then
		table.insert( path, 1, current.link )
	-- end
	return path
end


return Pathfinding