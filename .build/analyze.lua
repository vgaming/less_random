local math = math

local function fact(n)
	local result = 1
	for i= 1, n do
		result = result * i
	end
	return result
end

_G.fact = fact

local function cnk(k, n)
	return fact(n) / fact(k) / fact(n-k) / math.pow(2, n)
end

_G.cnk = cnk

local function prob(fract, strikes)
	local result = 1
	for need = 0, math.ceil(strikes * fract) - 1 do
		result = result - cnk(need, strikes)
	end
	return result
end
_G.prob = prob

local function percent(x)
	return math.floor(x * 100 + 0.5)
end

function print_stats(strikes)
	print(strikes,
		percent(1 - math.pow(0.5, strikes)),
		percent(prob(0.5 / 2, strikes)),
		percent(prob(0.8 / 2, strikes))
	)
end
