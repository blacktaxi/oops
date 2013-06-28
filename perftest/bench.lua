local _ = require 'moses'

local function time(action)
  local startTime = os.clock()
  action()
  local endTime = os.clock()  
  return endTime - startTime
end

local function sum(list)
  return _.reduce(list, function (a, b) return a + b end, 0)
end

local function average(list)
  return sum(list) / _.count(list)
end

function bench(benchmark)
  print('Timing ' .. benchmark.name .. '...')

  local min_iterations = benchmark.iterations or 500000
  local repeats = 5

  local action = benchmark.action()

  local proper_time = function (action, min_time)
    local min_time = min_time or 1.0
    local total_time = 0.0
    local total_iterations = 0
    collectgarbage()
    repeat
      total_time = total_time + time(function ()
        for _ = 0, min_iterations do
          action()
        end
      end)
      total_iterations = total_iterations + min_iterations
    until total_time >= min_time
    print(total_iterations, total_time)
    return total_time / total_iterations
  end

  local empty_tpi = proper_time(function () end)
  local bench_tpi = proper_time(action)

  print('Finished.')

  return { benchmark, 1 / (bench_tpi - empty_tpi) }
end

return {
  bench
}