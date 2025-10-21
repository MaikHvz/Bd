package com.dolphinconsulting.asignaciones.exception;

public class AsignacionException extends RuntimeException {
    
    public AsignacionException(String message) {
        super(message);
    }
    
    public AsignacionException(String message, Throwable cause) {
        super(message, cause);
    }
}