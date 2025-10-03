/**
 * @description Utility class to prevent trigger recursion by tracking execution context
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class TriggerRecursionHelper {
    
    // Static sets to track which triggers have already run in this transaction
    private static Set<String> executedTriggers = new Set<String>();
    
    // Static maps to track recursion depth for specific operations
    private static Map<String, Integer> recursionDepth = new Map<String, Integer>();
    
    // Maximum allowed recursion depth
    private static final Integer MAX_RECURSION_DEPTH = 3;
    
    /**
     * @description Checks if a trigger has already been executed in this transaction
     * @param triggerName Name of the trigger to check
     * @return Boolean indicating if trigger has already run
     */
    public static Boolean hasAlreadyRun(String triggerName) {
        return executedTriggers.contains(triggerName);
    }
    
    /**
     * @description Marks a trigger as having been executed
     * @param triggerName Name of the trigger to mark as executed
     */
    public static void setHasRun(String triggerName) {
        executedTriggers.add(triggerName);
    }
    
    /**
     * @description Checks if recursion depth has been exceeded for a specific operation
     * @param operationName Name of the operation to check depth for
     * @return Boolean indicating if recursion limit has been exceeded
     */
    public static Boolean isRecursionExceeded(String operationName) {
        Integer currentDepth = recursionDepth.get(operationName);
        if (currentDepth == null) {
            currentDepth = 0;
        }
        return currentDepth >= MAX_RECURSION_DEPTH;
    }
    
    /**
     * @description Increments the recursion depth for a specific operation
     * @param operationName Name of the operation to increment depth for
     */
    public static void incrementRecursionDepth(String operationName) {
        Integer currentDepth = recursionDepth.get(operationName);
        if (currentDepth == null) {
            currentDepth = 0;
        }
        recursionDepth.put(operationName, currentDepth + 1);
    }
    
    /**
     * @description Decrements the recursion depth for a specific operation
     * @param operationName Name of the operation to decrement depth for
     */
    public static void decrementRecursionDepth(String operationName) {
        Integer currentDepth = recursionDepth.get(operationName);
        if (currentDepth != null && currentDepth > 0) {
            recursionDepth.put(operationName, currentDepth - 1);
        }
    }
    
    /**
     * @description Resets the execution tracking (used for testing)
     */
    @TestVisible
    private static void resetExecutionTracking() {
        executedTriggers.clear();
        recursionDepth.clear();
    }
    
    /**
     * @description Gets the current recursion depth for an operation (used for testing)
     * @param operationName Name of the operation
     * @return Current recursion depth
     */
    @TestVisible
    private static Integer getCurrentRecursionDepth(String operationName) {
        return recursionDepth.get(operationName);
    }
}