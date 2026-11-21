import { Module } from '@nestjs/common';
import { FirebaseModule } from '../firebase/firebase.module.js';
import { NotaryService } from './notary.service.js';
import { NotaryTimer } from './notary.timer.js';

@Module({
  imports: [FirebaseModule],
  providers: [NotaryService, NotaryTimer],
  exports: [NotaryService],
})
export class NotaryModule {}