/** Required External Modules */
import mongoose from "mongoose";
import * as dotenv from "dotenv";

/** Required App Modules */

dotenv.config();
/** Mongo DB Connection String */
if (!process.env.MONGODB_URI) {
  
  console.error("MONGODB_URI not available in ENV");
  process.exit(1);
}

const MONGODB_URI: string = process.env.MONGODB_URI;

const conn = mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  useFindAndModify: false,
  useCreateIndex: true,
});

export const connectDB = async() => {
  try {
    console.log(process.env.MONGODB_URI);
    await conn;
    console.log("DATABASE CONNECTED");
  } catch (error) {
    console.log(error)
  }
}
export default mongoose;

export const CHAINS_COLLECTION = "chains";
