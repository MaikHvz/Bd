package com.dolphinconsulting.asignaciones.repository;

import com.dolphinconsulting.asignaciones.model.Profesional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProfesionalRepository extends JpaRepository<Profesional, Long> {
}