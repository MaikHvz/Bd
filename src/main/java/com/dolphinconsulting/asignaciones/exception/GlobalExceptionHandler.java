package com.dolphinconsulting.asignaciones.exception;

import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(DataAccessException.class)
    public ModelAndView handleDatabaseError(HttpServletRequest request, DataAccessException ex) {
        ModelAndView mav = new ModelAndView();
        mav.addObject("mensaje", "Error en la base de datos: " + ex.getMostSpecificCause().getMessage());
        mav.addObject("exito", false);
        mav.addObject("url", request.getRequestURL());
        mav.setViewName("error");
        return mav;
    }

    @ExceptionHandler(Exception.class)
    public ModelAndView handleGeneralError(HttpServletRequest request, Exception ex) {
        ModelAndView mav = new ModelAndView();
        mav.addObject("mensaje", "Error en la aplicación: " + ex.getMessage());
        mav.addObject("exito", false);
        mav.addObject("url", request.getRequestURL());
        mav.setViewName("error");
        return mav;
    }

    // Para las solicitudes API REST
    @ExceptionHandler(value = {AsignacionException.class})
    public ResponseEntity<Object> handleAsignacionException(AsignacionException ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("mensaje", ex.getMessage());
        body.put("exito", false);
        
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }
}