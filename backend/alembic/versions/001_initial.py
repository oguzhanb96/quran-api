"""
Alembic migrasyon dosyası örneği
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '001'
down_revision = None

def upgrade():
    # Users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('full_name', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.Column('is_premium', sa.Boolean(), default=False),
        sa.Column('created_at', sa.DateTime(), default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), default=sa.func.now(), onupdate=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email')
    )
    op.create_index('ix_users_email', 'users', ['email'], unique=True)
    op.create_index('ix_users_id', 'users', ['id'], unique=False)
    
    # Surahs table
    op.create_table(
        'surahs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('number', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('english_name', sa.String(), nullable=False),
        sa.Column('english_name_translation', sa.String(), nullable=True),
        sa.Column('revelation_type', sa.String(), nullable=True),
        sa.Column('verses_count', sa.Integer(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('number')
    )
    op.create_index('ix_surahs_number', 'surahs', ['number'], unique=True)
    
    # Verses table
    op.create_table(
        'verses',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('surah_id', sa.Integer(), nullable=False),
        sa.Column('number', sa.Integer(), nullable=False),
        sa.Column('text_arabic', sa.Text(), nullable=False),
        sa.Column('text_translation', sa.Text(), nullable=True),
        sa.Column('juz', sa.Integer(), nullable=True),
        sa.Column('page', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['surah_id'], ['surahs.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Favorites table
    op.create_table(
        'favorites',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('surah_id', sa.Integer(), nullable=True),
        sa.Column('verse_id', sa.Integer(), nullable=True),
        sa.Column('dua_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['surah_id'], ['surahs.id'], ),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Bookmarks table
    op.create_table(
        'bookmarks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('surah_id', sa.Integer(), nullable=False),
        sa.Column('verse_number', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['surah_id'], ['surahs.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # User settings table
    op.create_table(
        'user_settings',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('language', sa.String(), default='tr'),
        sa.Column('theme', sa.String(), default='light'),
        sa.Column('quran_font_size', sa.Integer(), default=24),
        sa.Column('translation_edition', sa.String(), default='tr.yildirim'),
        sa.Column('prayer_method', sa.Integer(), default=13),
        sa.Column('notification_enabled', sa.Boolean(), default=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )
    
    # Prayer time cache table
    op.create_table(
        'prayer_time_cache',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('method', sa.Integer(), nullable=False),
        sa.Column('date', sa.String(), nullable=False),
        sa.Column('fajr', sa.String(), nullable=True),
        sa.Column('sunrise', sa.String(), nullable=True),
        sa.Column('dhuhr', sa.String(), nullable=True),
        sa.Column('asr', sa.String(), nullable=True),
        sa.Column('maghrib', sa.String(), nullable=True),
        sa.Column('isha', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), default=sa.func.now()),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_prayer_cache_location_date', 'prayer_time_cache', ['latitude', 'longitude', 'method', 'date'], unique=False)

def downgrade():
    op.drop_table('prayer_time_cache')
    op.drop_table('user_settings')
    op.drop_table('bookmarks')
    op.drop_table('favorites')
    op.drop_table('verses')
    op.drop_table('surahs')
    op.drop_table('users')
