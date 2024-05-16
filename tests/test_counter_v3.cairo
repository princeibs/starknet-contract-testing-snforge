use starknet::{ContractAddress, get_caller_address};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, CheatSpan, spy_events, SpyOn,
    EventSpy, EventFetcher, EventAssertions, Event,
};
use sandbox::counter_v3::{
    ICounterV3Dispatcher, ICounterV3DispatcherTrait, ICounterV3SafeDispatcher,
    ICounterV3SafeDispatcherTrait, CounterV3
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
    let contract_address = deploy_contract("CounterV3");

    let counter_v3_dispatcher = ICounterV3Dispatcher { contract_address };

    let owner = counter_v3_dispatcher.get_owner();
    assert_eq!(Accounts::owner(), owner);
}

#[test]
fn test_emitted_events() {
    let contract_address = deploy_contract("CounterV3");
    let counter_v3_dispatcher = ICounterV3Dispatcher { contract_address };
    let initial_count = counter_v3_dispatcher.get_count();
    assert_eq!(0, initial_count);

    start_prank(CheatTarget::One(contract_address), Accounts::owner());
    let mut spy = spy_events(SpyOn::One(contract_address));
    assert_eq!(0, spy._id,);

    counter_v3_dispatcher.increase_count(5);

    // spy
    //     .assert_emitted(
    //         @array![
    //             (
    //                 contract_address,
    //                 CounterV3::Event::StoredCount(
    //                     CounterV3::StoredCount { new_count: 5, caller: Accounts::owner() }
    //                 )
    //             )
    //         ]
    //     )
    // assert_eq!(0, spy.events.len()); 

    spy.fetch_events();

    assert_eq!(1, spy.events.len());

    let (from, event) = spy.events.at(0);
    assert!(from == @contract_address, "Emmited from wrong address");
    assert!(event.keys.len() == 1, "Keys should be 1");
    assert!(
        event.keys.at(0) == @selector!("StoredEvent"), "Wrong event name"
    ); // To assert the name property we have to hash a string with the selector! macro.
    assert!(event.data.len() == 1, "There should be one data");

    counter_v3_dispatcher.increase_count(6);
    assert!(spy.events.len() == 1, "There should be one event"); // Still one event

    spy.fetch_events();
    assert!(spy.events.len() == 2, "There should be two events");
}
