--[[
TheNexusAvenger

Attempts to solve footplanting.
This code is heavily "zombified" off of a project by
Stravant, and is taken from Nexus VR Character Model V1
with minimal changes. It really needs to be replaced by
someone who better unstands foot placement. No automated
tests are done on this code.
--]]

local FootPlanter = {}


local CFnew,CFAngles = CFrame.new,CFrame.Angles
local V3new = Vector3.new
local rad,atan2,acos = math.rad,math.atan2,math.acos
local min,max,abs,log = math.min,math.max,math.abs,math.log



function FootPlanter:CreateSolver(CenterPart,ScaleValue)
	--Heavily modified code from Stravant
	local FootPlanterClass = {}
	
	local ignoreModel = CenterPart.Parent
	
	local LEG_GAP = 1.2
	--
	local STRIDE_FORWARD = 1.7 / 2
	local STRIDE_BACKWARD = 3.3 / 2
	local STRIDE_HEIGHT = 0.6
	local STRIDE_RESTING = 1
	--
	local WALK_SPEED_VR_THRESHOLD = 2
	local FOOT_MAX_SPEED_FACTOR = 2
	--
	local WALK_CYCLE_POWER = 1
	--
	local FOOT_ANGLE = rad(5)
	
	
	
	local function flatten(CF)
		local X,Y,Z = CF.X,CF.Y,CF.Z
		local LX,LZ = CF.lookVector.X,CF.lookVector.Z
		
		return CFnew(X,Y,Z) * CFAngles(0,atan2(LX,LZ),0)
	end
	
	local lastPosition,lastPollTime
	local overrideVelocityWithZero = false
	local function getVelocity(CF)
		if overrideVelocityWithZero then
			overrideVelocityWithZero = true
			
			local curTime = tick()
			lastPosition = CF.p
			
			return V3new()
		end
		
		if lastPollTime then
			local curTime = tick()
			local newPosition = CF.p
			
			local velocity = (newPosition - lastPosition) * 1/(curTime - lastPollTime)
			lastPollTime = curTime
			lastPosition = newPosition
			
			return velocity
		else
			lastPollTime = tick()
			lastPosition = CF.p
			
			return V3new()
		end
	end
	
	local function getWalkSpeed(velocity)
		return V3new(velocity.x,0,velocity.z).magnitude
	end
	
	local function getWalkDirection(velocity)
		if velocity.magnitude > 0. then
			return velocity.unit
		else
			return V3new(0,0,-1)
		end
	end
	
	local function isWalking(velocity)
		return getWalkSpeed(velocity) > WALK_SPEED_VR_THRESHOLD
	end

	local CurrentScale = 1
	local function getBaseCFrame()
		return CenterPart.CFrame * CFnew(0,-CenterPart.Size.Y/2 - (CurrentScale * 2),0)
	end
	
	local function getBaseRotationY()
		local lookVector = getBaseCFrame().lookVector
		return atan2(lookVector.X,lookVector.Z)
	end
	
	local FindCollidablePartOnRay = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("FindCollidablePartOnRay"))
	local function FindPartOnRay(ray,ignore)
		return FindCollidablePartOnRay(ray.Origin,ray.Direction,ignore)
	end
	
	
	
	
	-- Leg data
	local mRightLeg, mLeftLeg, mRightArm, mLeftArm;
	local mLegs = {}
	local lastCF
	local function initLegs()
		local cf = flatten(getBaseCFrame(CenterPart.CFrame))
		lastCF = cf
		mRightLeg = {
			OffsetModifier = CFnew(-LEG_GAP/2, 0, 0);
			Side = -1;
			--
			StepCycle = 0;
			FootPosition = cf*CFnew(-LEG_GAP/2, 0, 0).p;
			LastStepTo = cf*CFnew(-LEG_GAP/2, 0, 0).p;
			Takeoff = cf*CFnew(-LEG_GAP/2, 0, 0).p;
		}
		mLeftLeg = {
			OffsetModifier = CFnew( LEG_GAP/2, 0, 0);
			Side = 1;
			--
			StepCycle = 0;
			FootPosition = cf*CFnew( LEG_GAP/2, 0, 0).p;
			LastStepTo = cf*CFnew(-LEG_GAP/2, 0, 0).p;
			Takeoff = cf*CFnew(-LEG_GAP/2, 0, 0).p;
		}
		mRightLeg.OtherLeg = mLeftLeg
		mLeftLeg.OtherLeg = mRightLeg
		mLegs = {mLeftLeg, mRightLeg}
	end
	
	local LastScale = 1
	local function UpdateScaling()
		local Multiplier = ScaleValue.Value / LastScale
		LastScale = ScaleValue.Value

		LEG_GAP = LEG_GAP * Multiplier
		STRIDE_FORWARD = STRIDE_FORWARD * Multiplier
		STRIDE_BACKWARD = STRIDE_BACKWARD * Multiplier
		STRIDE_HEIGHT = STRIDE_HEIGHT * Multiplier
		STRIDE_RESTING = STRIDE_RESTING * Multiplier

		mRightLeg.OffsetModifier = CFnew(-LEG_GAP/2, 0, 0)
		--[[mRightLeg.FootPosition
		mRightLeg.LastStepTo
		mRightLeg.Takeoff
			 = ;
			Side = -1;
			--
			StepCycle = 0;
			 = lastCF*CFnew(-LEG_GAP/2, 0, 0).p;
			 = lastCF*CFnew(-LEG_GAP/2, 0, 0).p;
			 = lastCF*CFnew(-LEG_GAP/2, 0, 0).p;
		}
		mLeftLeg = {
			OffsetModifier = CFnew( LEG_GAP/2, 0, 0);
			Side = 1;
			--
			StepCycle = 0;
			FootPosition = lastCF*CFnew( LEG_GAP/2, 0, 0).p;
			LastStepTo = lastCF*CFnew(-LEG_GAP/2, 0, 0).p;
			Takeoff = lastCF*CFnew(-LEG_GAP/2, 0, 0).p;
		}]]
	end
	ScaleValue.Changed:Connect(function()
		if mRightLeg then
			UpdateScaling()
		end
	end)


	local mAirborneFraction = 0
	local mLandedFraction = 0
	local mCurrentSpeed = 1
	local mStableStanding = false
	
	local function getStrideForward()
		if mCurrentSpeed > 0 then
			return STRIDE_FORWARD + STRIDE_FORWARD*1*mCurrentSpeed
		else
			return STRIDE_FORWARD + STRIDE_FORWARD*0.5*mCurrentSpeed
		end
	end
	
	local function getStrideFull()
		if mCurrentSpeed > 0 then
			return (STRIDE_FORWARD + STRIDE_BACKWARD) + (STRIDE_FORWARD + STRIDE_BACKWARD)*1.5*mCurrentSpeed
		else
			return (STRIDE_FORWARD + STRIDE_BACKWARD) + (STRIDE_FORWARD + STRIDE_BACKWARD)*0.5*mCurrentSpeed
		end
	end

	local function snapDown(pos)
		local orig, dir = (pos + V3new(0, 2, 0)), V3new(0, -500, 0)
		local hit, at = FindPartOnRay(Ray.new(orig, dir), ignoreModel)
		if hit then
			local hit1, at1 = FindPartOnRay(Ray.new(orig + V3new(0,    0,  0.01), dir), ignoreModel)
			local hit2, at2 = FindPartOnRay(Ray.new(orig + V3new(0,    0, -0.01), dir), ignoreModel)				
			local hit3, at3 = FindPartOnRay(Ray.new(orig + V3new(0.01, 0,  0   ), dir), ignoreModel)
			local norm;
			
			if hit1 and hit2 and hit3 then
				norm = (at1 - at2):Cross(at2 - at3).unit
				if norm.Y < 0 then
					norm = -norm
				end					
			end
			
			return at, norm
		else
			return pos, V3new(0, 1, 0)
		end
	end
	
	local function fixFeetPositionsY()
		for _,leg in pairs(mLegs) do
			local targetPos,norm = snapDown(leg.FootPosition)
			leg.FootPosition = targetPos
		end
	end
	
	local lastTime
	function FootPlanterClass:GetFeetCFrames()
		if not mLeftLeg then
			initLegs()
			UpdateScaling()
		end
		
		local curTime = tick()
		if not lastTime then lastTime = curTime end
		local dt = curTime - lastTime
		lastTime = curTime
		
		local velocity = getVelocity(CenterPart.CFrame)
		local speed = getWalkSpeed(velocity)
		local realBaseCF = flatten(CenterPart.CFrame)
		local baseCF = realBaseCF
		local baseAxis = baseCF.lookVector
		local baseAxisPerp = baseAxis:Cross(V3new(0, 1, 0))
		local walkAxis = getWalkDirection(velocity)
		local walkAxisPerp = walkAxis:Cross(V3new(0, 1, 0))
		
		--
		mCurrentSpeed = max(-1, min(1, log(speed/16)/log(2)))
		--
		local leftStepping = mLeftLeg.StepCycle > 0
		local rightStepping = mRightLeg.StepCycle > 0
		--
				
		local function spline(t2, n, p)
			if n == 1 then
				return p[1]
			else
				local t1 = (1 - t2)
				for i = 1, n-1 do
					p[i] = t1*p[i] + t2*p[i+1]
				end
				return spline(t2, n-1, p)
			end
		end
			
		local function positionFootByCycle(leg, stepTarget)
			local baseVector = stepTarget - leg.Takeoff
			local sideVector = walkAxisPerp*leg.Side
			local baseLen = baseVector.magnitude
			local towardsSide = sideVector*(LEG_GAP/2)*0.3
			local towardsTop = V3new(0, 1.3*STRIDE_HEIGHT*(1 / leg.StepSpeedMod), 0)
			local topPoint = leg.Takeoff + baseVector * 1/2 + towardsTop + towardsSide
			local nextPoint = leg.Takeoff + baseVector * 0.9 + towardsTop + towardsSide
			--local a, b, c = leg.Takeoff, topPoint, stepTarget
			--local fb = leg.StepCycle
			--fb = fb^(_G.A or WALK_CYCLE_POWER)
			--local fa = 1-fb
			--
			--local footDesiredPos = fa*fa*a + 2*fa*fb*b + fb*fb*c
			local fb = leg.StepCycle^(_G.A or WALK_CYCLE_POWER)
			local footDesiredPos = spline(fb, 4, {leg.Takeoff, topPoint, nextPoint, stepTarget})
			--makeP(CFnew(footDesiredPos))
			if (footDesiredPos - leg.FootPosition).magnitude > dt*speed*FOOT_MAX_SPEED_FACTOR then
				local forcePos = (1 - leg.StepCycle) * leg.FootPosition + leg.StepCycle * footDesiredPos
				local movePos = leg.FootPosition + (footDesiredPos - leg.FootPosition).unit * dt*speed*FOOT_MAX_SPEED_FACTOR
				if (forcePos - footDesiredPos).magnitude < (movePos - footDesiredPos).magnitude then
					footDesiredPos = forcePos
				else
					footDesiredPos = movePos
				end
			end
			leg.FootPosition = footDesiredPos
			leg.LastStepTo = stepTarget
		end
		--
		local isCharacterWalking = isWalking(velocity)
		if isCharacterWalking then
			mStableStanding = false
		end
		--
		if isCharacterWalking then
			-- Get the desired ahead step
			local centeringMod = walkAxisPerp * (LEG_GAP/2) * 0.5
			local rightDesiredAheadStep = (baseCF * mRightLeg.OffsetModifier + getStrideForward()*walkAxis - mRightLeg.Side*centeringMod).p
			local leftDesiredAheadStep  = (baseCF *  mLeftLeg.OffsetModifier + getStrideForward()*walkAxis - mLeftLeg.Side*centeringMod).p
			local rightNorm, leftNorm;
			rightDesiredAheadStep, rightNorm = snapDown(rightDesiredAheadStep)
			leftDesiredAheadStep, leftNorm = snapDown(leftDesiredAheadStep)
			if not rightStepping or not mRightLeg.AheadStep or (rightDesiredAheadStep - mRightLeg.AheadStep).magnitude < dt*speed then
				mRightLeg.AheadStep = rightDesiredAheadStep
			else
				mRightLeg.AheadStep = mRightLeg.AheadStep + (rightDesiredAheadStep - mRightLeg.AheadStep).unit * dt*speed*2
			end
			mRightLeg.NormalHint = rightNorm
			if not leftStepping or not mLeftLeg.AheadStep or (leftDesiredAheadStep - mLeftLeg.AheadStep).magnitude < dt*speed then
				mLeftLeg.AheadStep = leftDesiredAheadStep
			else
				mLeftLeg.AheadStep = mLeftLeg.AheadStep + (leftDesiredAheadStep - mLeftLeg.AheadStep).unit * dt*speed*2
			end
			mLeftLeg.NormalHint = leftNorm
			
			local strideFactor = 0.9 - 0.3*max(0, mCurrentSpeed)
			local stepSpeed = speed / getStrideFull() * strideFactor
			
			-- Which legs are stepping?
			if not leftStepping and not rightStepping then
				-- Neither leg is stepping pick up the closer leg into the step
				if mAirborneFraction < 0.8 then -- don't pick up feet if we just landed
					if (mLeftLeg.FootPosition - mLeftLeg.AheadStep).magnitude < (mRightLeg.FootPosition - mRightLeg.AheadStep).magnitude then
						-- step p1
						local fracThere = min(0.9, max(0, (mLeftLeg.FootPosition - mLeftLeg.AheadStep).magnitude / getStrideFull()))
						mLeftLeg.StepSpeedMod = 1 / (1 - fracThere)
						mLeftLeg.StepCycle = dt
						mLeftLeg.Takeoff = mLeftLeg.FootPosition
					else
						-- step p2
						local fracThere = min(0.9, max(0, (mRightLeg.FootPosition - mRightLeg.AheadStep).magnitude / getStrideFull()))
						mRightLeg.StepSpeedMod = 1 / (1 - fracThere)
						mRightLeg.StepCycle = dt
						mRightLeg.Takeoff = mRightLeg.FootPosition
					end
				end
			elseif leftStepping and rightStepping then
				-- Both legs are stepping
				-- just step both legs
				-- The leg closer to |aheadStep| should step there, and the
				-- other leg should 
				for _, leg in pairs(mLegs) do
					leg.StepCycle = min(1, leg.StepCycle + dt*stepSpeed*leg.StepSpeedMod)
					positionFootByCycle(leg, leg.AheadStep)
					if leg.StepCycle == 1 then
						leg.StepCycle = 0
					end
				end
			else
				-- One leg is stepping.
				-- Step the one leg, and see if the other needs to enter a step
				for _, leg in pairs(mLegs) do
					if leg.StepCycle > 0 then
						-- Step this leg
						leg.StepCycle = min(1, leg.StepCycle + dt*stepSpeed*leg.StepSpeedMod)
						positionFootByCycle(leg, leg.AheadStep)
						
						-- Check if leg.Other needs to start a step
						if leg.StepCycle > strideFactor then
							leg.OtherLeg.StepSpeedMod = 1
							leg.OtherLeg.StepCycle = dt
							leg.OtherLeg.Takeoff = leg.OtherLeg.FootPosition
							positionFootByCycle(leg.OtherLeg, leg.AheadStep)
						end
						
						if leg.StepCycle == 1 then
							leg.StepCycle = 0
						end
						
						break
					end
				end
			end
		else
			local stepSpeed = 2			
			
			-- Not walking, we need to try to get to a suitable base position
			if leftStepping or rightStepping then
				for _, leg in pairs(mLegs) do
					if leg.StepCycle > 0 then
						leg.StepCycle = min(1, leg.StepCycle + dt*stepSpeed)
						local restingPos = (baseCF * leg.OffsetModifier).p
						local toVec = (leg.LastStepTo - restingPos)
						local targetPos;
						if toVec.magnitude > STRIDE_RESTING then
							targetPos = restingPos + (toVec.unit * STRIDE_RESTING)
						else
							targetPos = leg.LastStepTo
						end
						local norm;
						targetPos, norm = snapDown(targetPos)
						leg.AheadStep = targetPos
						leg.NormalHint = norm
						positionFootByCycle(leg, targetPos)
						if leg.StepCycle == 1 then
							leg.StepCycle = 0
						end
					else
						
					end
				end
			else
				fixFeetPositionsY()
			end
			
			-- Now, we stepped both legs. If both legs are resting now. See if 
			-- they are on roughly opposite offsets from where they should be.
			if mRightLeg.StepCycle == 0 and mLeftLeg.StepCycle == 0 then
				local rightResting = (baseCF * mRightLeg.OffsetModifier).p
				local leftResting = (baseCF * mLeftLeg.OffsetModifier).p
				local rightSep = mRightLeg.FootPosition - rightResting
				local leftSep = mLeftLeg.FootPosition - leftResting
				--
				local tooFar = abs(rightSep:Dot(baseAxis) - leftSep:Dot(baseAxis)) > 3
				local thetaBetweenFeet = acos(min(1, max(-1, rightSep.unit:Dot(leftSep.unit))))
				local distBetweenFeet = abs(rightSep.magnitude - leftSep.magnitude)
				--
				if rightSep:Dot(baseAxisPerp) > LEG_GAP/4 then
					mStableStanding = false
					mRightLeg.Takeoff = mRightLeg.FootPosition
					mRightLeg.StepCycle = dt
					--mRightLeg.LastStepTo = rightResting - baseAxisPerp*0.5
					local modLeftSep = leftSep.unit * 0.5
					if leftSep.magnitude == 0 then
						modLeftSep = -baseAxisPerp*0.5
					elseif leftSep:Dot(baseAxisPerp) > 0 then
						modLeftSep = (leftSep - 2*baseAxisPerp*leftSep:Dot(baseAxisPerp)).unit*0.5
					end
					mRightLeg.LastStepTo = rightResting + modLeftSep
					if (mRightLeg.LastStepTo - mRightLeg.Takeoff).magnitude < 0.5 then
						mRightLeg.StepCycle = 0
					end
					local fracThere = min(0.9, max(0, (mRightLeg.FootPosition - mRightLeg.LastStepTo).magnitude / getStrideFull()))
					mRightLeg.StepSpeedMod = 1 / (1 - fracThere)
				elseif leftSep:Dot(baseAxisPerp) < -LEG_GAP/4 then
					mStableStanding = false
					mLeftLeg.Takeoff = mLeftLeg.FootPosition
					mLeftLeg.StepCycle = dt
					--mLeftLeg.LastStepTo = leftResting + baseAxisPerp*0.5	
					local modRightSep = rightSep.unit * 0.5
					if rightSep.magnitude == 0 then
						modRightSep = baseAxisPerp*0.5
					elseif rightSep:Dot(baseAxisPerp) < 0 then
						modRightSep = (rightSep - 2*baseAxisPerp*rightSep:Dot(baseAxisPerp)).unit*0.5
					end
					mLeftLeg.LastStepTo = leftResting + modRightSep
					if (mRightLeg.LastStepTo - mRightLeg.Takeoff).magnitude < 0.5 then
						mRightLeg.StepCycle = 0
					end					
					local fracThere = min(0.9, max(0, (mLeftLeg.FootPosition - mLeftLeg.LastStepTo).magnitude / getStrideFull()))
					mLeftLeg.StepSpeedMod = 1 / (1 - fracThere)	
				elseif not mStableStanding and (thetaBetweenFeet < rad(150) or distBetweenFeet > 0.2 or tooFar) and mAirborneFraction < 0.5 then
					mStableStanding = true
					-- Step the foot further from the rest pos
					local furtherLeg, furtherResting, otherSep;
					if rightSep.magnitude > leftSep.magnitude then
						furtherLeg = mRightLeg
						furtherResting = rightResting
						otherSep = leftSep
					else
						furtherLeg = mLeftLeg
						furtherResting = leftResting
						otherSep = rightSep
					end
					--
					furtherLeg.StepCycle = dt
					furtherLeg.Takeoff = furtherLeg.FootPosition
					furtherLeg.StepSpeedMod = 1
					if tooFar then
						furtherLeg.LastStepTo = furtherResting - 0.5*otherSep
					else
						furtherLeg.LastStepTo = furtherResting - otherSep
					end
					if (furtherLeg.Takeoff - furtherLeg.LastStepTo).magnitude < 0.2 then
						furtherLeg.StepCycle = 0
					end
				end
			end
			fixFeetPositionsY()
		end
		
		local leftFootPosition,rightFootPosition = mLeftLeg.FootPosition,mRightLeg.FootPosition
		local footAngle = getBaseRotationY()
		local leftFootRotation = CFAngles(0,FOOT_ANGLE + footAngle,0)
		local rightFootRotation = CFAngles(0,-FOOT_ANGLE + footAngle,0)
		return CFnew(leftFootPosition) * leftFootRotation,CFnew(rightFootPosition) * rightFootRotation
	end
	
	function FootPlanterClass:OffsetFeet(Offset)
		overrideVelocityWithZero = true
		for _,leg in pairs(mLegs) do
			leg.FootPosition = leg.FootPosition + Offset
			leg.LastStepTo = leg.LastStepTo + Offset
			if leg.Takeoff then leg.Takeoff = leg.Takeoff + Offset end
			if leg.AheadStep then leg.AheadStep = leg.AheadStep + Offset end
		end
		overrideVelocityWithZero = true
	end
	
	return FootPlanterClass
end



return FootPlanter
