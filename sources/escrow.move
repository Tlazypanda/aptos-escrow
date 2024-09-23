module deployer_address::escrowv1 {

    use std::string;
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    struct ResourceInfo has key {
        source: address,
        resource_cap: account::SignerCapability
    }

    struct EscrowInfo has key {
        lockup_time: u8,
        is_approved: bool,
        initiator: address,
        escrow_expiry_time: u64,
    }

    const ENOT_APPROVED : u64 = 1;
    const EONLY_OWNER :u64 = 2;
    const EALREADY_APPROVED :u64 = 3;
    const ELOCKUP_NOT_ELAPSED :u64 = 4;
    const ENOT_ENOUGH_FUNDS: u64 = 5;

    public entry fun create_escrow_entry(owner: signer, amount: u64, seed: vector<u8>){
        let vault_addr = create_escrow(owner, amount, seed);
    }

    public fun create_escrow(owner: signer, amount: u64, seed: vector<u8>) : address{

        let (vault, vault_signer_cap) = account::create_resource_account(&owner, seed);
        let resource_account_from_cap = account::create_signer_with_capability(&vault_signer_cap);

        move_to<ResourceInfo>(&vault, ResourceInfo{source: signer::address_of(&owner), resource_cap: vault_signer_cap});
        let escrow_expiry_time = timestamp::now_seconds() + 1209600;
        move_to<EscrowInfo>(&owner, EscrowInfo{initiator: signer::address_of(&owner), is_approved: false, lockup_time: 14, escrow_expiry_time: escrow_expiry_time});

        let vault_addr = signer::address_of(&vault);

        aptos_account::transfer(&owner, vault_addr, amount);
        vault_addr
    }

    public entry fun fund_new_milestone(owner: signer, amount: u64, vault_addr: address) {
        coin::transfer<AptosCoin>(&owner, vault_addr, amount);
    }

    public entry fun modify_lockup_dur(owner: signer, new_dur: u64) acquires EscrowInfo{
        let owner_addr = signer::address_of(&owner);
        let escrow_info = borrow_global_mut<EscrowInfo>(owner_addr);
        assert!(owner_addr == escrow_info.initiator, EONLY_OWNER);
        escrow_info.escrow_expiry_time = new_dur;
    }

    // can only be called 14 days after the escrow creation 
    public entry fun cancel_txn(owner: &signer, vault_res_acc: address) acquires ResourceInfo, EscrowInfo {

        let owner_addr = signer::address_of(owner);
        let resource_info = borrow_global<ResourceInfo>(vault_res_acc);
        let escrow_info = borrow_global<EscrowInfo>(owner_addr);
        assert!(owner_addr == resource_info.source, EONLY_OWNER);
        assert!(timestamp::now_seconds() >= escrow_info.escrow_expiry_time, ELOCKUP_NOT_ELAPSED);
        assert!(escrow_info.is_approved == false, EALREADY_APPROVED);

        let resource_account_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);
        let balance = coin::balance<AptosCoin>(vault_res_acc);
        coin::transfer<AptosCoin>(&resource_account_from_cap, owner_addr,balance);

    }

    public entry fun update_work_status(owner: &signer) acquires EscrowInfo{
        let owner_addr = signer::address_of(owner);
        let escrow_info = borrow_global_mut<EscrowInfo>(owner_addr);
        assert!(owner_addr == escrow_info.initiator, EONLY_OWNER);

        escrow_info.is_approved = true;
    }

    public entry fun reject_work_status(owner: &signer) acquires EscrowInfo{
        let owner_addr = signer::address_of(owner);
        let escrow_info = borrow_global_mut<EscrowInfo>(owner_addr);
        assert!(owner_addr == escrow_info.initiator, EONLY_OWNER);

        escrow_info.is_approved = false;
    }


    public entry fun complete_txn(receiver_addr: address, owner_addr: address, amount: u64, vault_res_acc: address) acquires EscrowInfo, ResourceInfo{

        let resource_info = borrow_global<ResourceInfo>(vault_res_acc);
        let escrow_info = borrow_global<EscrowInfo>(owner_addr);

        assert!(escrow_info.is_approved == true, ENOT_APPROVED);

        let resource_account_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);

        let balance = coin::balance<AptosCoin>(vault_res_acc);
        let transfer_amount;

        assert!(amount<= balance, ENOT_ENOUGH_FUNDS);

        if(amount>(balance*7)/10){
            transfer_amount = amount;
        }
        else{
            transfer_amount = (balance*7)/10;
        };

        coin::transfer<AptosCoin>(&resource_account_from_cap, receiver_addr, transfer_amount);

    }

    // #[test(creator = @deployer_address, receiver = @0x42)]
    // fun init_test(creator: signer, receiver: address) acquires EscrowInfo, ResourceInfo{
    //     let creator_address = signer::address_of(&creator);
        
    //     account::create_account_for_test(creator_address);
    //     let vault_acc = create_escrow(creator, 5, vector[0u8, 1u8, 2u8]);

    //     let new_dur = timestamp::now_seconds();
    //     modify_lockup_dur(creator, new_dur);

    //     update_work_status(&creator);
    //     complete_txn(receiver, creator_address, 4, vault_acc);
    //     assert!(coin::balance<AptosCoin>(receiver) == 4, 7);
    //     assert!(coin::balance<AptosCoin>(vault_acc) == 1, 7);

    // }


}