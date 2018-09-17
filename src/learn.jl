"""
    learn!(rlsetup)

Runs an [`rlsetup`](@ref RLSetup) with learning.
"""
function learn!(rlsetup)
    @unpack learner, policy, fillbuffer, preprocessor, buffer, environment, stoppingcriterion = rlsetup
    if isempty(buffer)
        obs = reset!(environment).observation
        s = preprocessstate(preprocessor, obs)
        a = policy(s)
        fillbuffer && push!(buffer, s, a)
    else
        lastturn = buffer[end]
        s, a = lastturn.nextstate, lastturn.nextaction
    end
    while true
        next_obs, r, isdone = interact!(environment, a)
        if isdone 
            next_obs = reset!(environment).observation
        end
        next_s = preprocessstate(preprocessor, next_obs)
        next_a = policy(next_s)

        fillbuffer &&  push!(buffer, r, isdone, next_s, next_a)
        rlsetup.islearning && update!(learner, buffer)

        for callback in rlsetup.callbacks
            callback!(callback, rlsetup, s, a, r, isdone)
        end

        isbreak!(stoppingcriterion, next_obs, a, r, isdone) && break
        a = next_a
    end
end

"""
    run!(rlsetup)

Runs an [`rlsetup`](@ref RLSetup) without learning.
"""
function run!(rlsetup; fillbuffer = false)
    @unpack islearning = rlsetup
    rlsetup.islearning = false
    tmp = rlsetup.fillbuffer
    rlsetup.fillbuffer = fillbuffer
    learn!(rlsetup)
    rlsetup.islearning = islearning
    rlsetup.fillbuffer = tmp
end

export learn!, run!
