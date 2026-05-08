-- SPDX-License-Identifier: CC-BY-NC-SA-4.0
Locales['en'] = {
    -- ==== bootstrap test ====
    ['_test.bootstrap'] = 'i18n bootstrap test (en)',
    ['_test.format'] = 'hello %s, you have %d items', -- args: name, count
    ['_test.fallback'] = 'this exists only in en',

    -- ==== dialog ====
    ['dialog.common.cancel'] = 'Cancel',
    ['dialog.doorbell.confirm'] = 'Ring',
    ['dialog.doorbell.content'] = 'You dont have a key for this property, would you like to ring the doorbell?',
    ['dialog.doorbell.header'] = 'Ring Doorbell',
    ['dialog.property_info.header'] = '%s %s', -- args: street, property_id
    ['dialog.property_info.line_description'] = '**Description:** %s',
    ['dialog.property_info.line_forsale'] = '**For Sale:** %s',
    ['dialog.property_info.line_owner'] = '**Owner:** %s',
    ['dialog.property_info.line_price'] = '**Price:** %s',
    ['dialog.property_info.line_region'] = '**Region:** %s',
    ['dialog.property_info.line_shell'] = '**Shell:** %s',
    ['dialog.property_info.line_street'] = '**Street:** %s',
    ['dialog.property_info.no'] = 'No',
    ['dialog.property_info.yes'] = 'Yes',
    ['dialog.purchase.confirm'] = 'Purchase',
    ['dialog.purchase.content'] = 'Are you sure you want to purchase %s %s for $%s?', -- args: street, id, amount
    ['dialog.purchase.header'] = 'Purchase Confirmation',
    ['dialog.raid.confirm'] = 'Raid',
    ['dialog.raid.content'] = 'Do you want to raid %s %s?', -- args: street, id
    ['dialog.raid.header'] = 'Raid',
    ['dialog.showcase.confirm'] = 'Yes',
    ['dialog.showcase.content'] = 'Do you want to showcase this property?',
    ['dialog.showcase.header'] = 'Showcase Property',

    -- ==== log ====
    ['log.apartment.creating'] = 'Creating new apartment for %s in %s', -- args: playerName, apartmentLabel (LocaleEn)
    ['log.furniture.player_bought'] = '**Player %s** bought furniture for **$%s**', -- args: playerName, price (LocaleEn)
    ['log.property.changed_apartment'] = '**Changed Apartment** with id: %s by: **%s** for **%s**',
    ['log.property.changed_description'] = '**Changed Description** of property with id: %s by: %s',
    ['log.property.changed_door'] = '**Changed Door** of property with id: %s by: %s',
    ['log.property.changed_for_sale'] = '**Changed For Sale** of property with id: %s by: %s',
    ['log.property.changed_garage'] = '**Changed Garage** of property with id: %s by: %s',
    ['log.property.changed_images'] = '**Changed Images** of property with id: %s by: %s',
    ['log.property.changed_price'] = '**Changed Price** of property with id: %s by: %s',
    ['log.property.changed_shell'] = '**Changed Shell** of property with id: %s by: %s',
    ['log.property.deleted'] = '**Property Deleted** with id: %s by: %s',
    ['log.property.house_bought'] = '**House Bought** by: **%s %s** for $%s from **%s %s** !', -- buyer first, last, price, realtor first, last

    -- ==== menu ====
    ['menu.access.give_description'] = 'Give Access',
    ['menu.access.give_option'] = 'Give Access',
    ['menu.access.give_title'] = 'Give Access',
    ['menu.access.manage_title'] = 'Manage Access',
    ['menu.access.remove_description'] = 'Remove Access',
    ['menu.access.revoke_option'] = 'Revoke Access',
    ['menu.access.revoke_title'] = 'Revoke Access',
    ['menu.apartments.list_title'] = 'Apartments',
    ['menu.apartments.raid_list_title'] = 'Apartments To Raid',
    ['menu.apartments.raid_option_title'] = 'Raid %s %s', -- args: apartmentLabel, propertyId
    ['menu.doorbell.title'] = 'People at the door',

    -- ==== notify ====
    ['notify.access.added'] = 'You added access to %s', -- args: fullName
    ['notify.access.already_has'] = 'This person already has access to this property!',
    ['notify.access.lost'] = 'You lost access to %s %s', -- args: streetOrApartment, propertyId
    ['notify.access.no_players_inside'] = 'No one is in the property',
    ['notify.access.none_to_revoke'] = 'No one has access to this property',
    ['notify.access.not_has'] = 'This person does not have access to this property!',
    ['notify.access.received'] = 'You got access to this property!',
    ['notify.access.removed'] = 'You removed access from %s',
    ['notify.apartment.already_in_tenant'] = 'You are already in this apartment',
    ['notify.apartment.moved_to'] = 'Your apartment is now at %s',
    ['notify.apartment.none_here'] = 'You dont have an apartment here.',
    ['notify.apartment.none_in_building'] = 'There are no apartments here.',
    ['notify.apartment.peer_already_in'] = 'The client is already assigned to this apartment.',
    ['notify.common.player_not_found'] = 'Player not found.',
    ['notify.door.refresh_distance'] = 'Go far away and come back for the door to update and open/close.',
    ['notify.doorbell.no_answer'] = 'No one answered the door.',
    ['notify.doorbell.no_visitors'] = 'No one is at the door',
    ['notify.doorbell.rang_wait'] = 'You rang the doorbell. Just wait...',
    ['notify.doorbell.someone_at_door'] = 'Someone is at the door.',
    ['notify.framework.property_title'] = 'Property',
    ['notify.furniture.cart_empty'] = 'Your cart is empty',
    ['notify.furniture.insufficient_funds'] = 'You don\'t have enough money!',
    ['notify.furniture.purchase_success'] = 'You bought furniture for $%s',
    ['notify.furniture.stash_not_empty'] = 'Stash is not empty',
    ['notify.purchase.already_own'] = 'You already own this property',
    ['notify.purchase.buyer_success'] = 'You have bought the property for $%s',
    ['notify.purchase.insufficient_bank'] = 'You do not have enough money in your bank account',
    ['notify.purchase.not_confirmed'] = 'You did not confirm the purchase',
    ['notify.property.not_owner'] = 'You are not the owner of this property!',
    ['notify.property.owner_only'] = 'Only the owner can do this.',
    ['notify.property.sold_previous_owner'] = 'Sold Property: %s %s',
    ['notify.raid.in_progress'] = 'Raid in progress',
    ['notify.raid.need_onduty'] = 'You must be onduty before performing a raid',
    ['notify.raid.need_rank'] = 'You must be a higher rank before performing a raid',
    ['notify.raid.need_stormram'] = 'You need a stormram to perform a raid',
    ['notify.raid.police_only'] = 'Only police officers are permitted to perform raids',
    ['notify.raid.property_being_raided'] = 'This Property is being Raided.',
    ['notify.raid.started'] = 'Raid started',
    ['notify.realtor.added_tenant'] = 'You have added %s to apartment %s', -- args: fullName, apartmentKey
    ['notify.realtor.apartment_changed'] = 'Changed Apartment of property with id: %s to %s',
    ['notify.realtor.client_already_owns'] = 'Client already owns this property',
    ['notify.realtor.client_insufficient_bank'] = 'Client does not have enough money in their bank account',
    ['notify.realtor.client_not_confirmed'] = 'Client did not confirm the purchase',
    ['notify.realtor.property_removed'] = 'Property with id: %s has been removed.',
    ['notify.realtor.sale_success'] = 'Client has bought the property for $%s',
    ['notify.spawn.furniture_radial_hint'] = 'Open radial menu for furniture menu and place down your stash and clothing locker.',
    ['notify.tenant.apartment_changed'] = 'Changed Apartment to %s',

    -- ==== radial ====
    ['radial.furniture_menu.label'] = 'Furniture Menu',
    ['radial.manage_property.label'] = 'Manage Property',

    -- ==== target ====
    ['target.apartment.enter'] = 'Enter Apartment',
    ['target.apartment.raid'] = 'Raid Apartment',
    ['target.apartment.see_all'] = 'See all apartments',
    ['target.common.leave'] = 'Leave',
    ['target.door.check'] = 'Check Door',
    ['target.doorbell.ring'] = 'Ring Doorbell',
    ['target.furniture.clothing'] = 'Clothing',
    ['target.furniture.storage'] = 'Storage',
    ['target.property.enter'] = 'Enter Property',
    ['target.property.info'] = 'Property Info',
    ['target.property.leave'] = 'Leave Property',
    ['target.property.raid'] = 'Raid Property',
    ['target.property.showcase'] = 'Showcase Property',

    -- ==== property (DB / UI description; not Discord log) ====
    ['property.description.apartment'] = 'This is %s\'s apartment in %s', -- args: fullName, apartmentLabel

    -- ==== ui ====
    ['ui.apartment.luxury_description'] = 'Luxury Apartments!',
    ['ui.garage.label_format'] = '%s%s Garage', -- args: street, propertyId (matches upstream concatenation)
}
