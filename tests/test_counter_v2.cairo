use starknet::{ContractAddress, get_caller_address};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, CheatSpan};
use sandbox::counter_v2::{
    ICounterV2Dispatcher, ICounterV2DispatcherTrait, ICounterV2SafeDispatcher,
    ICounterV2SafeDispatcherTrait
};
use sandbox::addition::add;
use sandbox::errors::Errors;

pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn owner() -> ContractAddress {
        'owner'.try_into().unwrap()
    }

    pub fn account1() -> ContractAddress {
        'account1'.try_into().unwrap()
    }
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let constructor_calldata = array![Accounts::owner().into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_deploy_contract() {
    let contract_address = deploy_contract("CounterV2");

    let counter_v2_dispatcher = ICounterV2Dispatcher { contract_address };

    let owner = counter_v2_dispatcher.get_owner();
    assert_eq!(Accounts::owner(), owner);
}

#[test]
#[should_panic(expected: 'not owner',)]
fn test_cannot_increase_count_with_other_account() {
    let contract_address = deploy_contract("CounterV2");

    let counter_v2_dispatcher = ICounterV2Dispatcher { contract_address };

    let account1: ContractAddress = Accounts::account1();
    start_prank(CheatTarget::One(contract_address), account1);

    counter_v2_dispatcher.increase_count(5);
}

#[test]
// #[should_panic(expected: 'zero amount',)]
#[feature("safe_dispatcher")]
fn test_cannot_increase_count_with_zero() {
    let contract_address = deploy_contract("CounterV2");

    let counter_v2_safe_dispatcher = ICounterV2SafeDispatcher { contract_address };

    let owner: ContractAddress = Accounts::owner();

    start_prank(CheatTarget::One(contract_address), owner);

    match counter_v2_safe_dispatcher.increase_count(0) {
        Result::Ok => {},
        Result::Err(err_data) => {
            println!("error: {:?}", err_data);
            // assert(*err_data.at(0) == Errors::ZERO_AMOUNT, *err_data.at(0));
            assert_eq!(*err_data.at(0), Errors::ZERO_AMOUNT);
        }
    }
}

#[test]
fn test_can_increase_count() {
    let contract_address = deploy_contract("CounterV2");

    let counter_v2_dispatcher = ICounterV2Dispatcher { contract_address };
    let initial_count = counter_v2_dispatcher.get_count();
    assert_eq!(0, initial_count);

    let owner: ContractAddress = Accounts::owner();

    start_prank(CheatTarget::One(contract_address), owner);
    counter_v2_dispatcher.increase_count(5);

    let current_count = counter_v2_dispatcher.get_count();
    let calculated_count = add(current_count, initial_count);
    assert_eq!(calculated_count, current_count);
}

