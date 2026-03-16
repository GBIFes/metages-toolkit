-- test para mostrar personas ligadas explicitamente a varios bodies (redundancia??)
-- asuncion: las personas solo deberian estar en el nivel mas bajo y que los otros hereden a la persona al visualizarlo


WITH RECURSIVE body_hierarchy AS (
    SELECT child_body_fk AS child, parent_body_fk AS ancestor
    FROM metages_ispartof
    
    UNION ALL
    
    SELECT bh.child, i.parent_body_fk
    FROM body_hierarchy bh
    JOIN metages_ispartof i
        ON bh.ancestor = i.child_body_fk
)

SELECT
    p_child.person_fk,
    b_child.citation  AS child_body,
    b_parent.citation AS ancestor_body
FROM body_hierarchy bh
JOIN metages_personinbody p_child
    ON p_child.body_fk = bh.child
JOIN metages_personinbody p_parent
    ON p_parent.body_fk = bh.ancestor
   AND p_parent.person_fk = p_child.person_fk
JOIN metages_body b_child
    ON b_child.body_id = p_child.body_fk
JOIN metages_body b_parent
    ON b_parent.body_id = p_parent.body_fk
ORDER BY p_child.person_fk;