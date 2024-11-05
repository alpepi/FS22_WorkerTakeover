--- Enable compatibility with Courseplay Mod

WTCourseplayCompatibility = {}

function WTCourseplayCompatibility.cpKeepCC(ajv)
    if ajv.spec_cpAIWorker ~= nil then
        ajv.spec_cpAIWorker.brakeToStop = false
    end
end
