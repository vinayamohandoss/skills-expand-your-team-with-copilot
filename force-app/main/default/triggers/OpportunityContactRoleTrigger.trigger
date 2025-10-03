/**
 * @description Trigger for OpportunityContactRole object to prevent recursion
 * @author GitHub Copilot
 * @date 2024
 */
trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, before update, after insert, after update) {
    
    // Prevent recursion using helper class
    String triggerContext = 'OpportunityContactRole_' + Trigger.operationType;
    
    if (TriggerRecursionHelper.isRecursionExceeded(triggerContext)) {
        System.debug('OpportunityContactRoleTrigger: Recursion limit exceeded for ' + triggerContext + ', skipping execution');
        return;
    }
    
    // Increment recursion depth
    TriggerRecursionHelper.incrementRecursionDepth(triggerContext);
    
    try {
        // Handle different trigger contexts
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                OpportunityContactRoleTriggerHandler.handleBeforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                OpportunityContactRoleTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                OpportunityContactRoleTriggerHandler.handleAfterInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                OpportunityContactRoleTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
    } finally {
        // Always decrement recursion depth in finally block
        TriggerRecursionHelper.decrementRecursionDepth(triggerContext);
    }
}