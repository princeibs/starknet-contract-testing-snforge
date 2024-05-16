use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};

use sandbox::counter::{ICounterDispatcher, ICounterDispatcherTrait};
use sandbox::errors::Errors;

pub fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let constructor_calldata = array![];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
#[should_panic(expected: ('zero amount',))]
fn test_cannot_increase_count_with_zero() {
    let contract_address = deploy_contract("CounterContract");
    let counter_dispatcher = ICounterDispatcher { contract_address };

    counter_dispatcher.increase_count(0);
}

#[test]
fn test_can_increase_count() {
    let contract_address = deploy_contract("CounterContract");
    let counter_dispatcher = ICounterDispatcher { contract_address };

    let initial_count = counter_dispatcher.get_count();
    assert_eq!(0, initial_count);

    counter_dispatcher.increase_count(9);

    let current_count = counter_dispatcher.get_count();
    assert_eq!(9, current_count);
}

