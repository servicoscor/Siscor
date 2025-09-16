package bugarin.t.comando.data

import android.content.Context
import androidx.room.Room
import bugarin.t.comando.data.CORDatabase
import bugarin.t.comando.data.CacheDao
import bugarin.t.comando.data.CacheManager
import com.google.gson.Gson
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideCORDatabase(
        @ApplicationContext context: Context
    ): CORDatabase {
        return Room.databaseBuilder(
            context,
            CORDatabase::class.java,
            "cor_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    @Singleton
    fun provideCacheDao(database: CORDatabase): CacheDao {
        return database.cacheDao()
    }

    @Provides
    @Singleton
    fun provideCacheManager(
        cacheDao: CacheDao,
        gson: Gson
    ): CacheManager {
        return CacheManager(cacheDao, gson)
    }
}