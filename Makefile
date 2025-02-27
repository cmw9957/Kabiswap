S ?= "" # 실행할 스크립트 이름 (필수)
ACCOUNT ?= kabi
SENDER ?= 0x97A008FE1887b1448313b69F4324194a8e2a739D
ARGS ?= "" # 추가 인자

# 스크립트 실행 함수
define run_script
	@if [ -z "$(S)" ]; then \
		echo "Error: S variable (script name) is required"; \
		exit 1; \
	fi
	@echo "Running script: $(S) on $(RPC_URL)"; \
	forge script script/$(S).s.sol --rpc-url $(RPC_URL) --account $(ACCOUNT) --sender $(SENDER) $(BROADCAST) -vvvv $(ARGS)
endef

define run_test
	@if [ -z "$(S)" ]; then \
		echo "Error: S variable (script name) is required"; \
		exit 1; \
	fi
	@echo "Running test: $(S) on $(RPC_URL)"; \
	forge test -vvvvv test/$(S).t.sol --rpc-url $(RPC_URL)
endef

.PHONY: solve simulate_local simulate_remote test

solve: RPC_URL=sepolia
solve: BROADCAST=--broadcast
solve:
	$(run_script)

simulate_local: RPC_URL=http://localhost:8545
simulate_local: BROADCAST=
simulate_local:
	$(run_script)

simulate_remote: RPC_URL=sepolia
simulate_remote: BROADCAST=
simulate_remote:
	$(run_script)

test: RPC_URL=http://localhost:8545
test: BROADCAST=
test:
	$(run_test)