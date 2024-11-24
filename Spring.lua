--!strict

local ErrorFormat = "%q is not a valid member of Spring."

export type Nlerpable = number | Vector2 | Vector3

local Spring = {_type = "Spring"}

type T_Spring<T = Nlerpable> = {
    New: (Initial: T, Damping: number, Speed: number, Clock: () -> number) -> Spring<T>,
    Reset: (Target: T?) -> nil,
    Impulse: (Self: Spring<T>, Velocity: T) -> nil,
    TimeSkip: (Self: Spring<T>, Delta: number) -> nil,

    Position: T,
    P: T,
    Velocity: T,
    V: T,
    Target: T,
    T: T,
    Damping: number,
    D: number,
    Speed: number,
    S: number,
    Clock: () -> number,

    _Clock: () -> number,
    _Time: number,
    _Position: T,
    _Velocity: T,
    _Target: T,
    _Damping: number,
    _Speed: number,
    _Initial: T,
}

export type Spring<T = Nlerpable> = typeof(setmetatable({} :: T_Spring<T>, Spring))

function Spring.New<T>(Initial: T, Damping: number?, Speed: number?, Clock: (() -> number)?)
    local LocalDamping = Damping or 1
    local LocalSpeed = Speed or 1
    local LocalClock = Clock or os.clock

    local Self = {
        _Clock = LocalClock;
        _Time = LocalClock();
        _Position = Initial;
        _Velocity = ((Initial :: any) * 0) :: T;
        _Target = Initial;
        _Damping = LocalDamping;
        _Speed = LocalSpeed;
        _Initial = Initial;
    }

    return setmetatable(Self :: T_Spring<T>, Spring)
end

local function Reset(Self: Spring, Target: Nlerpable?)
    local Now = Self._Clock()
    local SetTo = Target or Self._Initial
    Self._Position = SetTo
    Self._Target = SetTo
    Self._Velocity = 0 * (SetTo :: any)
    Self._Time = Now
end

Spring.Reset = Reset

local function Impulse<T>(Self: Spring<T>, Velocity: T)
    Self.Velocity = (Self.Velocity :: any) + Velocity
end

Spring.Impulse = Impulse

local function _PositionVelocity(Self: Spring, Now: number)
    local CurrentPosition = Self._Position
    local CurrentVelocity = Self._Velocity
    local TargetPosition = Self._Target
    local DampingFactor = Self._Damping
    local Speed = Self._Speed

    local DeltaTime = Speed * (Now - Self._Time)
    local DampingSquared = DampingFactor * DampingFactor

    local AngFreq, SinTheta, CosTheta
    if DampingSquared < 1 then
        AngFreq = math.sqrt(1 - DampingSquared)
        local Exponential = math.exp(-DampingFactor * DeltaTime) / AngFreq
        CosTheta = Exponential * math.cos(AngFreq * DeltaTime)
        SinTheta = Exponential * math.sin(AngFreq * DeltaTime)
    elseif DampingSquared == 1 then
        AngFreq = 1
        local Exponential = math.exp(-DampingFactor * DeltaTime) / AngFreq
        CosTheta, SinTheta = Exponential, Exponential * DeltaTime
    else
        AngFreq = math.sqrt(DampingSquared - 1)
        local AngFreq2 = 2 * AngFreq
        local U = math.exp((-DampingFactor + AngFreq) * DeltaTime) / AngFreq2
        local V = math.exp((-DampingFactor - AngFreq) * DeltaTime) / AngFreq2
        CosTheta, SinTheta = U + V, U - V
    end

    local PullToTarget = 1 - (AngFreq * CosTheta + DampingFactor * SinTheta)
    local VelPosPush = SinTheta / Speed
    local VelPushRate = Speed * SinTheta
    local VelocityDecay = AngFreq * CosTheta - DampingFactor * SinTheta

    local PositionDifference = TargetPosition :: any - CurrentPosition

    local NewPosition =
        CurrentPosition +
        PositionDifference * PullToTarget +
        CurrentVelocity :: any * VelPosPush

    local NewVelocity =
        PositionDifference * VelPushRate +
        CurrentVelocity :: any * VelocityDecay

    return NewPosition, NewVelocity
end

local function TimeSkip(Self: Spring, Delta: number)
    local Now = Self._Clock()
    local Position, Velocity = _PositionVelocity(Self, Now + Delta)
    Self._Position = Position
    Self._Velocity = Velocity
    Self._Time = Now
end

Spring.TimeSkip = TimeSkip

function Spring.__index(Self: Spring, Index)
    if Spring[Index] then
        return Spring[Index]
    elseif Index == "Position" or Index == "P" then
        local Position, _ = _PositionVelocity(Self, Self._Clock())
        return Position
    elseif Index == "Velocity" or Index == "V" then
        local _, Velocity = _PositionVelocity(Self, Self._Clock())
        return Velocity
    elseif Index == "Target" or Index == "T" then
        return Self._Target
    elseif Index == "Damping" or Index == "D" then
        return Self._Damping
    elseif Index == "Speed" or Index == "S" then
        return Self._Speed
    elseif Index == "Clock" then
        return Self._Clock
    end
    error(string.format(ErrorFormat, tostring(Index)), 2)
end

function Spring.__newindex(Self: Spring, Index, Value: any)
    local Now = Self._Clock()
    if Index == "Position" or Index == "P" then
        local _, Velocity = _PositionVelocity(Self, Now)
        Self._Position = Value
        Self._Velocity = Velocity
        Self._Time = Now
    elseif Index == "Velocity" or Index == "V" then
        local Position, _ = _PositionVelocity(Self, Now)
        Self._Position = Position
        Self._Velocity = Value
        Self._Time = Now
    elseif Index == "Target" or Index == "T" then
        local Position, Velocity = _PositionVelocity(Self, Now)
        Self._Position = Position
        Self._Velocity = Velocity
        Self._Target = Value
        Self._Time = Now
    elseif Index == "Damping" or Index == "D" then
        local Position, Velocity = _PositionVelocity(Self, Now)
        Self._Position = Position
        Self._Velocity = Velocity
        Self._Damping = Value
        Self._Time = Now
    elseif Index == "Speed" or Index == "S" then
        local Position, Velocity = _PositionVelocity(Self, Now)
        Self._Position = Position
        Self._Velocity = Velocity
        Self._Speed = Value < 0 and 0 or Value
        Self._Time = Now
    elseif Index == "Clock" then
        local Position, Velocity = _PositionVelocity(Self, Now)
        Self._Position = Position
        Self._Velocity = Velocity
        Self._Clock = Value
        Self._Time = Value()
    else
        error(string.format(ErrorFormat, tostring(Index)), 2)
    end
end

return Spring
