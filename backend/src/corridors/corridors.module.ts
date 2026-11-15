import { Module } from '@nestjs/common';
import { CorridorsService } from './corridors.service.js';


@Module({
  providers: [CorridorsService],
  exports: [CorridorsService],
})
export class CorridorsModule {}