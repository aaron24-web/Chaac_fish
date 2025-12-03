-- Script para arreglar la tabla game_rooms y permitir usuarios de Firebase

-- 1. Eliminar la restricción de llave foránea (Foreign Key) que conecta con Supabase Auth
-- Esto es necesario porque ahora usaremos usuarios de Firebase, no de Supabase.
ALTER TABLE public.game_rooms DROP CONSTRAINT IF EXISTS game_rooms_host_id_fkey;

-- 2. Eliminar las políticas de seguridad (RLS) antiguas que causan conflicto
-- Estas políticas dependen de que host_id sea UUID, por eso fallan al cambiar el tipo.
DROP POLICY IF EXISTS "Authenticated users can create rooms" ON public.game_rooms;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.game_rooms;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.game_rooms;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.game_rooms;
DROP POLICY IF EXISTS "Host can update own room" ON public.game_rooms;

-- 3. Cambiar el tipo de las columnas host_id y guest_id a TEXT
-- Esto permitirá guardar los IDs de Firebase (que son texto).
ALTER TABLE public.game_rooms ALTER COLUMN host_id TYPE text;

-- Intentar cambiar guest_id si existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'game_rooms' AND column_name = 'guest_id') THEN
        ALTER TABLE public.game_rooms ALTER COLUMN guest_id TYPE text;
    END IF;
END $$;

-- 4. Crear una nueva política de acceso
-- Como estamos en desarrollo/pruebas, permitiremos acceso público a esta tabla
-- para evitar bloqueos. Luego se puede restringir más si es necesario.
ALTER TABLE public.game_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public access"
ON public.game_rooms
FOR ALL
USING (true)
WITH CHECK (true);
