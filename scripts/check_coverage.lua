#!/usr/bin/env lua
-- Check coverage threshold
local threshold = tonumber(os.getenv("COVERAGE_THRESHOLD")) or tonumber(arg[1]) or 100

local report_file = io.open("luacov.report.out", "r")
if not report_file then
  print("❌ No coverage report found. Run 'make test' first.")
  os.exit(1)
end

for line in report_file:lines() do
  local file, hits, missed, cov = line:match("^(src/oops%.lua)%s+(%d+)%s+(%d+)%s+([%d.]+)%%")
  if file then
    local coverage = tonumber(cov)
    print(string.format("Coverage: %.2f%% (threshold: %.0f%%)", coverage, threshold))
    if coverage < threshold then
      print(string.format("❌ Coverage %.2f%% is below threshold %.0f%%", coverage, threshold))
      os.exit(1)
    else
      print("✅ Coverage meets requirement")
    end
    report_file:close()
    os.exit(0)
  end
end

report_file:close()
print("❌ Could not find coverage data for src/oops.lua")
os.exit(1)
