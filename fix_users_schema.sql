-- Script ACTUALIZADO (Versión 3) para arreglar la tabla users
-- Este script maneja:
-- 1. Restricciones de llave foránea (Foreign Keys) que conectan con Supabase Auth.
-- 2. Políticas de seguridad (RLS) que dependen de tipos UUID.

-- 1. Eliminar la restricción de llave foránea (Foreign Key)
-- Esto es CRÍTICO porque 'users.id' ya no coincidirá con 'auth.users.id' (UUID)
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 2. Eliminar TODAS las políticas existentes que puedan causar conflictos
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.users;
DROP POLICY IF EXISTS "Users can update own profile." ON public.users;

-- 3. Alterar la tabla users para que id sea text
ALTER TABLE public.users ALTER COLUMN id TYPE text;

-- 4. Actualizar la función complete_level
DROP FUNCTION IF EXISTS public.complete_level(int, int, int);
DROP FUNCTION IF EXISTS public.complete_level(text, int, int);

CREATE OR REPLACE FUNCTION public.complete_level(
  user_id_param text,
  level_param int,
  score_param int
)
RETURNS void AS $$
BEGIN
  -- Insertar o actualizar el nivel desbloqueado
  INSERT INTO public.users (id, story_level_unlocked)
  VALUES (user_id_param, level_param + 1)
  ON CONFLICT (id) DO UPDATE
  SET story_level_unlocked = GREATEST(users.story_level_unlocked, level_param + 1);
END;
$$ LANGUAGE plpgsql;

-- 5. Habilitar acceso básico (Modo Desarrollo)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access" ON public.users FOR ALL USING (true) WITH CHECK (true);
