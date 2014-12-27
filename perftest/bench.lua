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

  local min_iterations = benchmark.iterations or 100000
  local action = benchmark.action()

  -- a function that times an action 'properly'
  local proper_time = function (action, min_time)
    -- minimal benchmark time
    local min_time = min_time or 1.0
    local total_time = 0.0
    local total_iterations = 0
    collectgarbage()
    local start_mem = collectgarbage('count')
    collectgarbage('stop')
    -- iterate until total time is >= minimal time
    repeat
      total_time = total_time + time(function ()
        for _ = 0, min_iterations do
          action()
        end
      end)
      total_iterations = total_iterations + min_iterations
    until total_time >= min_time
    local end_mem = collectgarbage('count')
    collectgarbage('restart')
    print(total_iterations, total_time)
    return total_time, total_iterations, (end_mem - start_mem)
  end

  -- measure overhead
  local overhead_time, overhead_iterations, overhead_mem = proper_time(function () end)
  local overhead_tpi = overhead_time / overhead_iterations
  local overhead_mpi = overhead_mem / overhead_iterations
  -- measure actual benchmark
  local full_time, full_iterations, full_mem = proper_time(action)
  local full_tpi = full_time / full_iterations
  local full_mpi = full_mem / full_iterations

  print('Finished.')

  return { benchmark, full_tpi - overhead_tpi, full_mpi - overhead_mpi }
end

return {
  bench
}