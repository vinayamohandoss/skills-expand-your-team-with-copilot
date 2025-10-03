/**
 * @description Handler class for Opportunity trigger
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class OpportunityTriggerHandler {
    
    /**
     * @description Handles before insert logic for Opportunity records
     * @param newRecords List of new Opportunity records
     */
    public static void handleBeforeInsert(List<Opportunity> newRecords) {
        System.debug('OpportunityTriggerHandler.handleBeforeInsert: Processing ' + newRecords.size() + ' records');
        
        // Add any before insert logic here
        validateOpportunities(newRecords);
    }
    
    /**
     * @description Handles before update logic for Opportunity records
     * @param newRecords List of new Opportunity records
     * @param oldRecordMap Map of old Opportunity records
     */
    public static void handleBeforeUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecordMap) {
        System.debug('OpportunityTriggerHandler.handleBeforeUpdate: Processing ' + newRecords.size() + ' records');
        
        // Add any before update logic here
        validateOpportunities(newRecords);
    }
    
    /**
     * @description Handles after insert logic for Opportunity records
     * @param newRecords List of new Opportunity records
     */
    public static void handleAfterInsert(List<Opportunity> newRecords) {
        System.debug('OpportunityTriggerHandler.handleAfterInsert: Processing ' + newRecords.size() + ' records');
        
        // Check for recursion before proceeding with OpportunityContactRole updates
        if (TriggerRecursionHelper.isRecursionExceeded('ContactRoleUpdate_FromOpportunity')) {
            System.debug('OpportunityTriggerHandler: Skipping OpportunityContactRole update due to recursion limit');
            return;
        }
        
        // Process contact role creation if needed
        createDefaultContactRoles(newRecords);
    }
    
    /**
     * @description Handles after update logic for Opportunity records
     * @param newRecords List of new Opportunity records
     * @param oldRecordMap Map of old Opportunity records
     */
    public static void handleAfterUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecordMap) {
        System.debug('OpportunityTriggerHandler.handleAfterUpdate: Processing ' + newRecords.size() + ' records');
        
        // Check for recursion before proceeding with OpportunityContactRole updates
        if (TriggerRecursionHelper.isRecursionExceeded('ContactRoleUpdate_FromOpportunity')) {
            System.debug('OpportunityTriggerHandler: Skipping OpportunityContactRole update due to recursion limit');
            return;
        }
        
        // Process contact role updates if needed
        List<Opportunity> changedRecords = new List<Opportunity>();
        for (Opportunity newRecord : newRecords) {
            Opportunity oldRecord = oldRecordMap.get(newRecord.Id);
            if (newRecord.StageName != oldRecord.StageName || newRecord.Amount != oldRecord.Amount) {
                changedRecords.add(newRecord);
            }
        }
        
        if (!changedRecords.isEmpty()) {
            updateRelatedContactRoles(changedRecords);
        }
    }
    
    /**
     * @description Validates opportunity data
     * @param opportunities List of Opportunity records to validate
     */
    private static void validateOpportunities(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            // Add validation logic here
            if (String.isBlank(opp.Name)) {
                opp.addError('Opportunity name is required');
            }
            
            if (opp.CloseDate < Date.today()) {
                opp.addError('Close date cannot be in the past');
            }
        }
    }
    
    /**
     * @description Creates default contact roles for new opportunities
     * @param opportunities List of Opportunity records that need default contact roles
     */
    private static void createDefaultContactRoles(List<Opportunity> opportunities) {
        // Increment recursion tracking to prevent circular updates
        TriggerRecursionHelper.incrementRecursionDepth('ContactRoleUpdate_FromOpportunity');
        
        try {
            List<OpportunityContactRole> contactRolesToInsert = new List<OpportunityContactRole>();
            
            for (Opportunity opp : opportunities) {
                // Only create default contact role if we haven't exceeded recursion and we have an account
                if (!TriggerRecursionHelper.isRecursionExceeded('ContactRoleUpdate_FromOpportunity') && 
                    opp.AccountId != null) {
                    
                    // Query for primary contact of the account
                    List<Contact> primaryContacts = [
                        SELECT Id, Name 
                        FROM Contact 
                        WHERE AccountId = :opp.AccountId 
                        AND IsPrimary__c = true 
                        LIMIT 1
                    ];
                    
                    if (!primaryContacts.isEmpty()) {
                        OpportunityContactRole contactRole = new OpportunityContactRole(
                            OpportunityId = opp.Id,
                            ContactId = primaryContacts[0].Id,
                            Role = 'Decision Maker',
                            IsPrimary = true
                        );
                        contactRolesToInsert.add(contactRole);
                    }
                }
            }
            
            if (!contactRolesToInsert.isEmpty()) {
                insert contactRolesToInsert;
            }
        } catch (QueryException e) {
            // Handle case where IsPrimary__c field doesn't exist
            System.debug('OpportunityTriggerHandler: IsPrimary__c field not found, skipping default contact role creation');
        } finally {
            // Always decrement recursion tracking
            TriggerRecursionHelper.decrementRecursionDepth('ContactRoleUpdate_FromOpportunity');
        }
    }
    
    /**
     * @description Updates related OpportunityContactRole records based on opportunity changes
     * @param opportunities List of Opportunity records that triggered the update
     */
    private static void updateRelatedContactRoles(List<Opportunity> opportunities) {
        // Increment recursion tracking to prevent circular updates
        TriggerRecursionHelper.incrementRecursionDepth('ContactRoleUpdate_FromOpportunity');
        
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for (Opportunity opp : opportunities) {
                opportunityIds.add(opp.Id);
            }
            
            List<OpportunityContactRole> contactRolesToUpdate = [
                SELECT Id, OpportunityId, Role, IsPrimary
                FROM OpportunityContactRole 
                WHERE OpportunityId IN :opportunityIds
            ];
            
            List<OpportunityContactRole> toUpdate = new List<OpportunityContactRole>();
            for (OpportunityContactRole contactRole : contactRolesToUpdate) {
                // Only update if we haven't exceeded recursion
                if (!TriggerRecursionHelper.isRecursionExceeded('ContactRoleUpdate_FromOpportunity')) {
                    // Update contact role based on opportunity stage
                    for (Opportunity opp : opportunities) {
                        if (contactRole.OpportunityId == opp.Id) {
                            String newRole = getContactRoleBasedOnStage(opp.StageName);
                            if (contactRole.Role != newRole) {
                                contactRole.Role = newRole;
                                toUpdate.add(contactRole);
                            }
                            break;
                        }
                    }
                }
            }
            
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            // Always decrement recursion tracking
            TriggerRecursionHelper.decrementRecursionDepth('ContactRoleUpdate_FromOpportunity');
        }
    }
    
    /**
     * @description Determines contact role based on opportunity stage
     * @param stageName Opportunity stage name
     * @return String representing the appropriate contact role
     */
    private static String getContactRoleBasedOnStage(String stageName) {
        if (String.isBlank(stageName)) {
            return 'Contact';
        }
        
        switch on stageName.toLowerCase() {
            when 'prospecting', 'qualification' {
                return 'Influencer';
            }
            when 'needs analysis', 'value proposition' {
                return 'Technical Buyer';
            }
            when 'proposal/price quote', 'negotiation/review' {
                return 'Decision Maker';
            }
            when 'closed won', 'closed lost' {
                return 'Economic Buyer';
            }
            when else {
                return 'Contact';
            }
        }
    }
}