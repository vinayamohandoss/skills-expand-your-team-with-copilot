/**
 * @description Trigger for Opportunity object to prevent recursion
 * @author GitHub Copilot
 * @date 2024
 */
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    
    // Prevent recursion using helper class
    String triggerContext = 'Opportunity_' + Trigger.operationType;
    
    if (TriggerRecursionHelper.isRecursionExceeded(triggerContext)) {
        System.debug('OpportunityTrigger: Recursion limit exceeded for ' + triggerContext + ', skipping execution');
        return;
    }
    
    // Increment recursion depth
    TriggerRecursionHelper.incrementRecursionDepth(triggerContext);
    
    try {
        // Handle different trigger contexts
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                OpportunityTriggerHandler.handleBeforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                OpportunityTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                OpportunityTriggerHandler.handleAfterInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                OpportunityTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
    } finally {
        // Always decrement recursion depth in finally block
        TriggerRecursionHelper.decrementRecursionDepth(triggerContext);
    }
}