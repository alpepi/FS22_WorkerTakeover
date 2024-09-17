--
-- FS22 Worker Takover mod
--
-- @author: alpepi
-- @date: 2024-09-16
-- @version: 1.0.0.0
--
-- @support and feedback: https://github.com/alpepi/FS22_WorkerTakeover
--

local function ccCheck(ajv)
    if ajv:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_OFF or ajv:getAIFieldWorkerIsTurning()
        or not ajv:getIsDrivingForward() or (ajv.spec_aiFieldWorker.aiDriveParams.maxSpeed ~= ajv:getSpeedLimit(true) and ajv.spec_aiFieldWorker.aiDriveParams.valid)
    then
        return false
    else
        return true
    end
end

local function isUnfoldedCheck(v, specF)
    if specF == nil or #specF.foldingParts == 0
        or not v:getIsFoldMiddleAllowed() or not v:getIsUnfolded()
        or specF.foldMoveDirection == -1 * specF.turnOnFoldDirection or specF.foldAnimTime == specF.foldMiddleAnimTime
    then
        return false
    else
        return true
    end
end

local function toggleAIVehicleOverwrite(aijobvehicle, superFunc)
    if aijobvehicle == nil then
        return (superFunc(aijobvehicle))
    end

    local turnOnCruiseCheck = nil
    local vehicles = nil
    local implements = nil
    local beforeVehicleStates = {}
    local beforeImplementStates = {}

    if aijobvehicle:getIsControlled() and aijobvehicle:getIsAIActive() then
        turnOnCruiseCheck = ccCheck(aijobvehicle)

        vehicles = aijobvehicle:getChildVehicles()
        if vehicles ~= nil then
            for i, vehicle in ipairs(vehicles) do
                beforeVehicleStates[i] = {
                    isUnfolded = isUnfoldedCheck(vehicle, vehicle.spec_foldable),
                    isTurnedOn = vehicle.spec_turnOnVehicle ~= nil and vehicle:getIsTurnedOn()
                }
            end
        end

        implements = aijobvehicle:getAttachedImplements()
        if implements ~= nil then
            for _, implement in ipairs(implements) do
                beforeImplementStates[implement.jointDescIndex] = {
                    isLowered = implement.object.spec_attachable.attacherJoint.allowsLowering and
                    implement.object:getIsLowered(true)
                }
            end
        end
    end

    local returnValue = superFunc(aijobvehicle)

    if aijobvehicle:getIsControlled() and (not aijobvehicle:getIsAIActive()) then
        if turnOnCruiseCheck then
            aijobvehicle:setCruiseControlMaxSpeed(aijobvehicle:getCruiseControlSpeed())
            aijobvehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE, false)
        end

        if vehicles ~= nil then
            for i, vehicle in ipairs(vehicles) do
                if beforeVehicleStates[i].isTurnedOn then
                    vehicle:setIsTurnedOn(true, false)
                end

                if beforeVehicleStates[i].isUnfolded then
                    vehicle:setFoldState(vehicle.spec_foldable.turnOnFoldDirection, false, false)
                end
            end
        end

        if implements ~= nil then
            for _, implement in ipairs(implements) do
                if beforeImplementStates[implement.jointDescIndex].isLowered then
                    implement.object:setLoweredAll(true, implement.jointDescIndex)

                    if implement.object.spec_attachable.lowerAnimation ~= nil and implement.object.playAnimation ~= nil then
                        local spec = implement.object.spec_attachable
                        implement.object:playAnimation(spec.lowerAnimation, spec.lowerAnimationSpeed,
                            implement.object:getAnimationTime(spec.lowerAnimation), false)
                    end
                end
            end
        end
    end

    return returnValue
end

AIJobVehicle.toggleAIVehicle = Utils.overwrittenFunction(AIJobVehicle.toggleAIVehicle, toggleAIVehicleOverwrite)