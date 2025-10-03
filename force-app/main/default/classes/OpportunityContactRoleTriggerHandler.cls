/**
 * @description Handler class for OpportunityContactRole trigger
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class OpportunityContactRoleTriggerHandler {
    
    /**
     * @description Handles before insert logic for OpportunityContactRole records
     * @param newRecords List of new OpportunityContactRole records
     */
    public static void handleBeforeInsert(List<OpportunityContactRole> newRecords) {
        System.debug('OpportunityContactRoleTriggerHandler.handleBeforeInsert: Processing ' + newRecords.size() + ' records');
        
        // Add any before insert logic here
        validateContactRoles(newRecords);
    }
    
    /**
     * @description Handles before update logic for OpportunityContactRole records
     * @param newRecords List of new OpportunityContactRole records
     * @param oldRecordMap Map of old OpportunityContactRole records
     */
    public static void handleBeforeUpdate(List<OpportunityContactRole> newRecords, Map<Id, OpportunityContactRole> oldRecordMap) {
        System.debug('OpportunityContactRoleTriggerHandler.handleBeforeUpdate: Processing ' + newRecords.size() + ' records');
        
        // Add any before update logic here
        validateContactRoles(newRecords);
    }
    
    /**
     * @description Handles after insert logic for OpportunityContactRole records
     * @param newRecords List of new OpportunityContactRole records
     */
    public static void handleAfterInsert(List<OpportunityContactRole> newRecords) {
        System.debug('OpportunityContactRoleTriggerHandler.handleAfterInsert: Processing ' + newRecords.size() + ' records');
        
        // Check for recursion before proceeding with Opportunity updates
        if (TriggerRecursionHelper.isRecursionExceeded('OpportunityUpdate_FromContactRole')) {
            System.debug('OpportunityContactRoleTriggerHandler: Skipping Opportunity update due to recursion limit');
            return;
        }
        
        // Process opportunity updates if needed
        updateRelatedOpportunities(newRecords);
    }
    
    /**
     * @description Handles after update logic for OpportunityContactRole records
     * @param newRecords List of new OpportunityContactRole records
     * @param oldRecordMap Map of old OpportunityContactRole records
     */
    public static void handleAfterUpdate(List<OpportunityContactRole> newRecords, Map<Id, OpportunityContactRole> oldRecordMap) {
        System.debug('OpportunityContactRoleTriggerHandler.handleAfterUpdate: Processing ' + newRecords.size() + ' records');
        
        // Check for recursion before proceeding with Opportunity updates
        if (TriggerRecursionHelper.isRecursionExceeded('OpportunityUpdate_FromContactRole')) {
            System.debug('OpportunityContactRoleTriggerHandler: Skipping Opportunity update due to recursion limit');
            return;
        }
        
        // Process opportunity updates if needed
        List<OpportunityContactRole> changedRecords = new List<OpportunityContactRole>();
        for (OpportunityContactRole newRecord : newRecords) {
            OpportunityContactRole oldRecord = oldRecordMap.get(newRecord.Id);
            if (newRecord.Role != oldRecord.Role || newRecord.IsPrimary != oldRecord.IsPrimary) {
                changedRecords.add(newRecord);
            }
        }
        
        if (!changedRecords.isEmpty()) {
            updateRelatedOpportunities(changedRecords);
        }
    }
    
    /**
     * @description Validates contact role data
     * @param contactRoles List of OpportunityContactRole records to validate
     */
    private static void validateContactRoles(List<OpportunityContactRole> contactRoles) {
        for (OpportunityContactRole contactRole : contactRoles) {
            // Add validation logic here
            if (String.isBlank(contactRole.Role)) {
                contactRole.addError('Role is required for Opportunity Contact Role');
            }
        }
    }
    
    /**
     * @description Updates related Opportunity records based on contact role changes
     * @param contactRoles List of OpportunityContactRole records that triggered the update
     */
    private static void updateRelatedOpportunities(List<OpportunityContactRole> contactRoles) {
        // Increment recursion tracking to prevent circular updates
        TriggerRecursionHelper.incrementRecursionDepth('OpportunityUpdate_FromContactRole');
        
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for (OpportunityContactRole contactRole : contactRoles) {
                if (contactRole.OpportunityId != null) {
                    opportunityIds.add(contactRole.OpportunityId);
                }
            }
            
            if (!opportunityIds.isEmpty()) {
                List<Opportunity> opportunitiesToUpdate = [
                    SELECT Id, Name, Description, 
                           (SELECT Id, Role, IsPrimary FROM OpportunityContactRoles)
                    FROM Opportunity 
                    WHERE Id IN :opportunityIds
                ];
                
                List<Opportunity> toUpdate = new List<Opportunity>();
                for (Opportunity opp : opportunitiesToUpdate) {
                    // Only update if we haven't exceeded recursion
                    if (!TriggerRecursionHelper.isRecursionExceeded('OpportunityUpdate_FromContactRole')) {
                        // Update opportunity description with contact role count
                        String roleDescription = 'Contact Roles: ' + opp.OpportunityContactRoles.size();
                        if (opp.Description != roleDescription) {
                            opp.Description = roleDescription;
                            toUpdate.add(opp);
                        }
                    }
                }
                
                if (!toUpdate.isEmpty()) {
                    update toUpdate;
                }
            }
        } finally {
            // Always decrement recursion tracking
            TriggerRecursionHelper.decrementRecursionDepth('OpportunityUpdate_FromContactRole');
        }
    }
}