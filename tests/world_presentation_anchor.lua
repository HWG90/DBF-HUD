-- Execute the real runtime/fixture contract in isolation from unrelated legacy checks.
DBF_CONTRACT_FILTER='runtime attaches without reticle travel clamp and falls back when projection fails'
dofile('tests/contracts.lua')
