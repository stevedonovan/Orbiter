-- orbiter.lua
local ok,orbiter = pcall(require, 'orbiter.init')
if not ok then
  package.path = '../?.lua;../?/init.lua;'..package.path
  orbiter = require 'orbiter.init'
end
return orbiter
