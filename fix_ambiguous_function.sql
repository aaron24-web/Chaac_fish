-- Script FINAL para arreglar la ambigüedad en complete_level
-- El error PGRST203 indica que hay múltiples funciones con el mismo nombre y argumentos similares.
-- Vamos a eliminar TODAS las variantes posibles antes de crear la correcta.

-- 1. Eliminar variante con BIGINT (la que probablemente está causando el conflicto con la vieja estructura)
DROP FUNCTION IF EXISTS public.complete_level(bigint, int, int);

-- 2. Eliminar variante con INT (por si acaso)
DROP FUNCTION IF EXISTS public.complete_level(int, int, int);

-- 3. Eliminar variante con TEXT (la nueva, para recrearla limpia)
DROP FUNCTION IF EXISTS public.complete_level(text, int, int);

-- 4. Crear la función CORRECTA que acepta TEXT para user_id
CREATE OR REPLACE FUNCTION public.complete_level(
  user_id_param text,
  level_param int,
  score_param int
)
RETURNS void AS $$
BEGIN
  -- Insertar o actualizar el nivel desbloqueado
  INSERT INTO public.users (id, story_level_unlocked, username, email)
  VALUES (user_id_param, level_param + 1, 'Player', 'no-email@placeholder.com')
  ON CONFLICT (id) DO UPDATE
  SET story_level_unlocked = GREATEST(users.story_level_unlocked, level_param + 1);
END;
$$ LANGUAGE plpgsql;
