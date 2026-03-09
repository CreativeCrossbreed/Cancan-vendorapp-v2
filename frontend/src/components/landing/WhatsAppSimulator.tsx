'use client';

import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { playWaterDrop, playDing } from './SoundEngine';

interface Message {
    id: number;
    type: 'bot' | 'user';
    text: string;
}

interface ButtonOption {
    label: string;
    value: string;
}

interface Step {
    botMessage: string;
    buttons: ButtonOption[];
    userReply?: (choice: string) => string;
}

const STEPS: Step[] = [
    {
        botMessage: 'Welcome to Can Can! How can we help you today?',
        buttons: [
            { label: 'Order Water Cans', value: 'order' },
            { label: 'Track My Order', value: 'track' },
            { label: 'Reorder Previous', value: 'reorder' },
        ],
    },
    {
        botMessage: 'Choose your brand:',
        buttons: [
            { label: 'Bisleri 20L — ₹70', value: 'Bisleri 20L' },
            { label: 'Kinley 20L — ₹65', value: 'Kinley 20L' },
            { label: 'Local Brand — ₹50', value: 'Local Brand' },
        ],
    },
    {
        botMessage: 'How many cans do you need?',
        buttons: [
            { label: '1 Can', value: '1' },
            { label: '2 Cans', value: '2' },
            { label: '5 Cans', value: '5' },
        ],
    },
    {
        botMessage: 'When should we deliver?',
        buttons: [
            { label: 'Morning 8-10am', value: 'Morning 8-10am' },
            { label: 'Afternoon 12-2pm', value: 'Afternoon 12-2pm' },
            { label: 'Evening 5-7pm', value: 'Evening 5-7pm' },
        ],
    },
];

export default function WhatsAppSimulator({ soundEnabled }: { soundEnabled: boolean }) {
    const [messages, setMessages] = useState<Message[]>([]);
    const [currentStep, setCurrentStep] = useState(0);
    const [isTyping, setIsTyping] = useState(false);
    const [choices, setChoices] = useState<Record<number, string>>({});
    const [isComplete, setIsComplete] = useState(false);
    const [started, setStarted] = useState(false);

    const addMessage = useCallback((type: 'bot' | 'user', text: string) => {
        setMessages((msgs) => [...msgs, { id: Date.now() + Math.random(), type, text }]);
    }, []);

    const startConversation = useCallback(() => {
        setStarted(true);
        setIsTyping(true);
        if (soundEnabled) playWaterDrop();
        setTimeout(() => {
            setIsTyping(false);
            addMessage('bot', STEPS[0].botMessage);
        }, 800);
    }, [addMessage, soundEnabled]);

    const handleChoice = useCallback(
        (choice: string, stepIndex: number) => {
            if (isTyping || isComplete) return;

            // User message
            addMessage('user', choice);
            if (soundEnabled) playWaterDrop();

            const newChoices = { ...choices, [stepIndex]: choice };
            setChoices(newChoices);

            const nextStep = stepIndex + 1;

            setIsTyping(true);

            setTimeout(() => {
                setIsTyping(false);

                if (nextStep < STEPS.length) {
                    addMessage('bot', STEPS[nextStep].botMessage);
                    setCurrentStep(nextStep);
                } else {
                    // Final confirmation
                    const brand = newChoices[1] || 'Bisleri 20L';
                    const qty = newChoices[2] || '2';
                    const time = newChoices[3] || 'Morning 8-10am';
                    const priceMap: Record<string, number> = { 'Bisleri 20L': 70, 'Kinley 20L': 65, 'Local Brand': 50 };
                    const price = (priceMap[brand] || 70) * parseInt(qty);

                    addMessage(
                        'bot',
                        `Order confirmed! ${qty}x ${brand} arriving at ${time}. Total: ₹${price}. Your nearest vendor has been notified.`
                    );
                    setIsComplete(true);
                    if (soundEnabled) playDing();
                }
            }, 700 + Math.random() * 500);
        },
        [addMessage, choices, isTyping, isComplete, soundEnabled]
    );

    const reset = useCallback(() => {
        setMessages([]);
        setCurrentStep(0);
        setChoices({});
        setIsComplete(false);
        setStarted(false);
    }, []);

    const showButtons = started && !isTyping && !isComplete;
    const step = STEPS[currentStep];

    return (
        <div className="w-[300px] sm:w-[320px] h-[580px] rounded-[48px] overflow-hidden bg-[#111b21] flex flex-col shadow-2xl border border-white/10">
            {/* Notch */}
            <div className="w-24 h-1.5 rounded-full bg-[#2a3942] mx-auto mt-3 mb-1.5" />

            {/* Status Bar */}
            <div className="flex justify-between items-center px-5 pt-0.5 pb-2 text-[10px] text-[#8696a0]">
                <span className="font-bold">9:41</span>
                <div className="flex gap-1.5">
                    <div className="w-3 h-2.5 rounded-[2px] bg-[#8696a0]/40" />
                    <div className="w-3 h-2.5 rounded-[2px] bg-[#8696a0]/40" />
                    <div className="w-3 h-2.5 rounded-[2px] bg-[#8696a0]/40" />
                </div>
            </div>

            {/* Header */}
            <div className="flex items-center gap-3 px-4 py-3 bg-[#1f2c34] border-b border-white/[0.04]">
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-cancan-primary to-cancan-secondary flex items-center justify-center text-white text-[11px] font-black shadow-lg">
                    CC
                </div>
                <div>
                    <div className="text-[#e9edef] text-[13px] font-bold">Can Can Water</div>
                    <div className="text-[#8696a0] text-[10px] flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#00a884] animate-pulse" />
                        online
                    </div>
                </div>
            </div>

            {/* Chat Area */}
            <div className="flex-1 px-3 py-4 overflow-y-auto flex flex-col gap-2 bg-[#0b141a] scrollbar-hide">
                {!started && (
                    <div className="flex-1 flex flex-col items-center justify-center gap-6 text-center px-4">
                        <div className="w-16 h-16 rounded-3xl bg-[#1f2c34] flex items-center justify-center text-2xl animate-bounce">
                            💧
                        </div>
                        <p className="text-[#8696a0] text-sm font-medium">Experience the Chennai water concierge in WhatsApp</p>
                        <button
                            className="w-full py-3.5 rounded-2xl bg-[#00a884] text-white font-black text-sm transition-all hover:bg-[#00c49a] active:scale-95 shadow-xl shadow-[#00a884]/20"
                            onClick={startConversation}
                        >
                            Start Demo Order
                        </button>
                    </div>
                )}

                <AnimatePresence>
                    {messages.map((msg) => (
                        <motion.div
                            key={msg.id}
                            className={`max-w-[85%] px-3.5 py-2.5 text-[12.5px] leading-relaxed relative ${msg.type === 'bot'
                                    ? 'self-start bg-[#1f2c34] text-[#e9edef] rounded-tr-xl rounded-br-xl rounded-bl-xl shadow-md'
                                    : 'self-end bg-[#005c4b] text-[#e9edef] rounded-tl-xl rounded-br-xl rounded-bl-xl shadow-md'
                                }`}
                            initial={{ opacity: 0, scale: 0.9, y: 10 }}
                            animate={{ opacity: 1, scale: 1, y: 0 }}
                            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
                        >
                            {msg.text}
                        </motion.div>
                    ))}
                </AnimatePresence>

                {isTyping && (
                    <motion.div
                        className="self-start flex gap-1.5 px-4 py-3.5 bg-[#1f2c34] rounded-tr-xl rounded-br-xl rounded-bl-xl mt-1 shadow-md"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                    >
                        <span className="w-1.5 h-1.5 rounded-full bg-[#8696a0] animate-bounce [animation-duration:1s] [animation-delay:-0.32s]" />
                        <span className="w-1.5 h-1.5 rounded-full bg-[#8696a0] animate-bounce [animation-duration:1s] [animation-delay:-0.16s]" />
                        <span className="w-1.5 h-1.5 rounded-full bg-[#8696a0] animate-bounce [animation-duration:1s]" />
                    </motion.div>
                )}

                {showButtons && step && (
                    <motion.div
                        className="flex flex-wrap gap-2 mt-4 pt-4 border-t border-white/[0.04]"
                        initial={{ opacity: 0, y: 15 }}
                        animate={{ opacity: 1, y: 0 }}
                    >
                        {step.buttons.map((btn) => (
                            <button
                                key={btn.value}
                                className="px-5 py-2 border border-[#2a3942] rounded-xl text-[#00a884] text-[11.5px] font-black transition-all hover:bg-[#00a884] hover:text-white hover:border-[#00a884] active:scale-95"
                                onClick={() => handleChoice(btn.label, currentStep)}
                            >
                                {btn.label}
                            </button>
                        ))}
                    </motion.div>
                )}

                {isComplete && (
                    <motion.button
                        className="self-center mt-6 px-6 py-2 border border-[#2a3942] rounded-full text-[#8696a0] text-[11px] font-black uppercase tracking-wider hover:text-white hover:border-white transition-all active:scale-95"
                        onClick={reset}
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                    >
                        Restart Simulation
                    </motion.button>
                )}
            </div>
        </div>
    );
}
